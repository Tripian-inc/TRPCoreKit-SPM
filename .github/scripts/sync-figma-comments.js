import fetch from 'node-fetch';
import fs from 'fs';
import path from 'path';

const FIGMA_TOKEN = process.env.FIGMA_TOKEN;
const GITHUB_TOKEN = process.env.GITHUB_TOKEN;
const FIGMA_FILE_KEY = process.env.FIGMA_FILE_KEY;
const GITHUB_REPO = process.env.GITHUB_REPO;

const PROCESSED_COMMENTS_FILE = '.github/data/processed-comments.json';

// Daha önce işlenmiş yorumları oku
function getProcessedComments() {
  try {
    if (fs.existsSync(PROCESSED_COMMENTS_FILE)) {
      const data = fs.readFileSync(PROCESSED_COMMENTS_FILE, 'utf8');
      return new Set(JSON.parse(data));
    }
  } catch (error) {
    console.log('No processed comments file found, starting fresh');
  }
  return new Set();
}

// İşlenmiş yorumları kaydet
function saveProcessedComments(processedSet) {
  const dir = path.dirname(PROCESSED_COMMENTS_FILE);
  if (!fs.existsSync(dir)) {
    fs.mkdirSync(dir, { recursive: true });
  }
  fs.writeFileSync(PROCESSED_COMMENTS_FILE, JSON.stringify([...processedSet], null, 2));
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
    // Daha önce işlenmiş yorumları yükle
    const processedComments = getProcessedComments();
    console.log(`📋 Already processed ${processedComments.size} comments`);

    // Figma yorumlarını getir
    console.log('📥 Fetching Figma comments...');
    const comments = await getFigmaComments();
    console.log(`✅ Found ${comments.length} total comments in Figma`);

    // Yeni yorumları filtrele
    const newComments = comments.filter(comment => !processedComments.has(comment.id));
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
        
        processedComments.add(comment.id);
        successCount++;
        
        // API rate limit'e takılmamak için kısa bekleme
        await new Promise(resolve => setTimeout(resolve, 1000));
      } catch (error) {
        console.error(`❌ Failed to create issue for comment ${comment.id}:`, error.message);
      }
    }

    // İşlenmiş yorumları kaydet
    saveProcessedComments(processedComments);
    console.log(`\n🎉 Successfully synced ${successCount}/${newComments.length} comments!`);

  } catch (error) {
    console.error('💥 Error during sync:', error);
    process.exit(1);
  }
}

main();
