//
//  PlanGenerateController.swift
//  TRPDataLayer
//
//  Created by Evren Yaşar on 14.08.2020.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation

class DailyTimelinePlanRequestLoop {
    var id: String
    var loop: Int
    
    init(id: String, loop: Int) {
        self.id = id
        self.loop = loop
    }
}

class TimelinePlanGenerateController {
    
    private var dailyPlanGeneraterInterval: Float = 2
    private var dailyPlanGeneraterLimit = 30
    public var fetchPlanUseCase: FetchTimelinePlanUseCase?
    
    private var dailyPlanRequestsCount = [DailyTimelinePlanRequestLoop]()
    
    
    
    init() {}
    
    
    /// Günün(TRPDailyPlanInfoModel) içindeki mekanların(planPois) dolu olup olmadığını denetler.
    /// Mekan listesi eğer yok ise kendi TRPTripController(self) içinde bi döngü oluşturur.
    ///
    /// - Parameter dailyPlan: Güne ait bilgilerin olduğu dizi
    /// - note: Soket server burayı tetikleyecek
    public func dailyPlanController(_ dailyPlan: TRPTimelinePlan,
                                    
                                    completed: @escaping (_ generated: Int, _ plan: TRPTimelinePlan)-> Void ) {
        let id = dailyPlan.id
        //Güne ait planın oluşturulup oluşturulmadığın "generate" değişkeni ile anlarız
        //Generate refactor
        
        //Note: Generated değerleri 3 tane değer alır; "0" "1" "-1"
        let generate = dailyPlan.generatedStatus
        
        
        if generate == 0 {// TRİP DAHA YARATILMADIS
            //Günler generate edilmese dahi belirli limit de kontrol edilir.
            if !dailyGeneraterLimitDone(dailyPlanId: id) {
                let time = dailyGeneraterInterval(dailyPlanId: id)
                print("[info] delay başladı")
                DispatchQueue.global().asyncAfter(deadline: .now() + Double(time)) {
                    print("[info] delay bitti")
                    self.dailyGeneraterIncrease(dailyPlanId: id)
                    
                    self.fetchPlanUseCase?.executeFetchPlan(id: id, completion: { [weak self] result in
                        switch result {
                        case .success(let _plan):
                            self?.dailyPlanController(_plan, completed: completed)
                        case .failure(let error):
                            ()//todo: error yönlendirlecek
                        }
                    })
                    print("[info] refetch")
                }
                
            }else {
                print("[Error] Plan couldn't generated")
            }
        }else if generate > 0 { //TRİP YARATILDI VE
            //Eğer dizinin eleman sayısı 0 ise plan tekrar bir kereliğe mahsus çekilr
            print("[info] generated 1")
            // TODO : - RETURN
            //changeCurrentDailyPlan(dailyPlan)
            completed(generate, dailyPlan)
        }else if generate < 0 {//Trip generate edildi ancak, saatden dolayı hiç bir mekan döndüremedi
            print("[info] generated -1")
            completed(generate, dailyPlan)
            // TODO : - RETURN
            //changeCurrentDailyPlan(dailyPlan)
        }
    }
    
    
    /// Gunun mekan listesi çekmek için limit uygulanır. 1 gün için en fazla dailyPlanGeneraterLimit (30) kadar denetleme yapılır.
    /// Denetlemeyi bu metod sağlar
    ///
    /// - Parameter dailyPlanId: Limiti kontrol edilecek dailyPlanın Id si
    /// - Returns: Eğer limit doldu ise true döner
    private func dailyGeneraterLimitDone(dailyPlanId: String) -> Bool{
        if let counter = dailyPlanRequestsCount.first(where: {$0.id == dailyPlanId}) {
            if counter.loop > dailyPlanGeneraterLimit {
                return true
            }
        }
        return false
    }
    
    
    /// DailyPlan' ın sunucudan kontrol edilmesi için Requestin kac sanayi beklemesi gerektiğini hesaplar
    ///
    /// - Parameter dailyPlanId: DailyPlanId
    /// - Returns: Requestion bekleyeceği aralık.
    private func dailyGeneraterInterval(dailyPlanId: String) -> Float {
        if let counter = dailyPlanRequestsCount.first(where: {$0.id == dailyPlanId}) {
            if counter.loop != 0 {
                return dailyPlanGeneraterInterval
            }
        }
        //Daha önce hiç loop yapmadıysa direk request çalışır. CÜnkü ilk defa başlamış demektir.
        return 0.0
    }
    
    /// DailyPlan'ın generate edilip edilmediği sayısını bir artırır
    ///
    /// - Parameter dailyPlanId: DailyPlanId
    private func dailyGeneraterIncrease(dailyPlanId: String) {
        if let index = dailyPlanRequestsCount.firstIndex(where: {$0.id == dailyPlanId}) {
            dailyPlanRequestsCount[index].loop += 1
            print("[Info] Plan: \(dailyPlanId)  Loop Count: \(dailyPlanRequestsCount[index].loop)")
        }else {
            dailyPlanRequestsCount.append(DailyTimelinePlanRequestLoop(id: dailyPlanId, loop: 1))
        }
    }
 
}
