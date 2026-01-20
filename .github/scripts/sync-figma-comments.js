import fetch from 'node-fetch';

const FIGMA_TOKEN = process.env.FIGMA_TOKEN;
const GITHUB_TOKEN = process.env.GITHUB_TOKEN;
const FIGMA_FILE_KEY = process.env.FIGMA_FILE_KEY;
const GITHUB_REPO = process.env.GITHUB_REPO;

// Sadece bu tarihten sonraki yorumları işle (YYYY-MM-DD formatında)
const START_DATE = new Date('2025-01-15'); // Bu tarihi değiştirin!

// GitHub'dan daha önce işlenmiş comment ID'leri getir
async function getProcessedCommentIds() {
  const processed = new Set();
  let page = 1;
  
  while (true) {
    const url = `https://api.github.com/repos/${GITHUB_REPO}/issues?labels=figma&state=all&per_page=100&page=${page}`;
    
    const response = await fetch(url, {
      headers: {
        'Authorization': `token ${GITHUB_TOKEN}`,
        'Accept': 'application/vnd.github.v3+json'
      }
    });

    if (!response.ok) {
      console.error('Failed to fetch existing issues');
      break;
    }

    const issues = await response.json();
    if (issues.length === 0) break;
    
    // Issue body'den Comment ID çıkar
    issues.forEach(issue => {
      const match = issue.body?.match(/\*\*Comment ID:\*\*\s*(.+)/);
      if (match) {
        processed.add(match[1].trim());
      }
    });
    
    page++;
  }
  
  return processed;
}

// Figma yorumlarını getir
async function getFigmaComments() {
  const url = `https://api.figma.com/v1/files/${FIGMA_FILE_KEY}/comments`;
  
  const response = await fetch(url, {
    headers: {
      'X-Figma-Token': FIGMA_TOKEN
    }
  });

  if (!response.ok) {
    throw new Error(`Figma API error: ${response.status} ${response.statusText}`);
  }

  const data = await response.json();
  return data.comments || [];
}

// GitHub issue oluştur
async function createGitHubIssue(comment) {
  const url = `https://api.github.com/repos/${GITHUB_REPO}/issues`;
  
  // Figma yorumundan bilgileri çıkar
  const commentText = comment.message;
  const author = comment.user?.handle || comment.user?.email || 'Unknown';
  const figmaUrl = `https://www.figma.com/design/${FIGMA_FILE_KEY}/?node-id=${comment.client_meta?.node_id || ''}`;
  
  // Issue başlığı ve içeriği
  const title = `[Figma] ${commentText.substring(0, 60)}${commentText.length > 60 ? '...' : ''}`;
  const body = `## Figma Comment

**Author:** ${author}
**Date:** ${new Date(comment.created_at).toLocaleString()}

### Comment:
${commentText}

---

**Figma Link:** [View in Figma](${figmaUrl})

**Comment ID:** ${comment.id}
`;

  const response = await fetch(url, {
    method: 'POST',
    headers: {
      'Authorization': `token ${GITHUB_TOKEN}`,
      'Accept': 'application/vnd.github.v3+json',
      'Content-Type': 'application/json'
    },
    body: JSON.stringify({
      title: title,
      body: body,
      labels: ['figma', 'design']
    })
  });

  if (!response.ok) {
    const errorData = await response.json();
    throw new Error(`GitHub API error: ${response.status} - ${JSON.stringify(errorData)}`);
  }

  return await response.json();
}

// Ana fonksiyon
async function main() {
  console.log('🚀 Starting Figma to GitHub sync...');
  
  try {
    // Daha önce işlenmiş yorumları GitHub'dan al
    console.log('📋 Fetching already processed comments from GitHub issues...');
    const processedComments = await getProcessedCommentIds();
    console.log(`✅ Already processed ${processedComments.size} comments`);

    // Figma yorumlarını getir
    console.log('📥 Fetching Figma comments...');
    const comments = await getFigmaComments();
    console.log(`✅ Found ${comments.length} total comments in Figma`);

    // Tarih filtresini uygula - sadece START_DATE'ten sonraki yorumlar
    const recentComments = comments.filter(comment => {
      const commentDate = new Date(comment.created_at);
      return commentDate >= START_DATE;
    });
    console.log(`📅 ${recentComments.length} comments are after ${START_DATE.toISOString().split('T')[0]}`);

    // Yeni yorumları filtrele
    const newComments = recentComments.filter(comment => !processedComments.has(comment.id));
    console.log(`🆕 Found ${newComments.length} new comments to process`);

    if (newComments.length === 0) {
      console.log('✨ No new comments to sync!');
      return;
    }

    // Her yeni yorum için GitHub issue oluştur
    let successCount = 0;
    for (const comment of newComments) {
      try {
        console.log(`\n📝 Processing comment: ${comment.id}`);
        const issue = await createGitHubIssue(comment);
        console.log(`✅ Created issue #${issue.number}: ${issue.html_url}`);
        
        successCount++;
        
        // API rate limit'e takılmamak için kısa bekleme
        await new Promise(resolve => setTimeout(resolve, 1000));
      } catch (error) {
        console.error(`❌ Failed to create issue for comment ${comment.id}:`, error.message);
      }
    }

    console.log(`\n🎉 Successfully synced ${successCount}/${newComments.length} comments!`);

  } catch (error) {
    console.error('💥 Error during sync:', error);
    process.exit(1);
  }
}

main();
