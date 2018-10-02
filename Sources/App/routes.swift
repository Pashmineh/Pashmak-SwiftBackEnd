import Vapor

/// Register your application's routes here.
public func routes(_ router: Router) throws {

  
  let userRoutes = UserRouteCollection()
  try router.register(collection: userRoutes)
  
  let debtController = DebtController()
  let eventController = EventController()
  
  
  let bearerDebt = router.grouped(Models.User.tokenAuthMiddleware())
  bearerDebt.post("debts", use: debtController.create)

  // MARK: - Checkin
  let checkinController = CheckinController()
  let bearerCheckin = router.grouped(Models.User.tokenAuthMiddleware())
  bearerCheckin.post("checkin", use: checkinController.create)
  bearerCheckin.get("checkins", use: checkinController.getAll)
  bearerCheckin.get("checkin", Checkin.parameter, use: checkinController.getCheckin)
  
  let bearerEvent = router.grouped(Models.User.tokenAuthMiddleware())
  bearerEvent.post("event", use: eventController.create)

  let transactionController = TransacrionRouteCollection()
  try router.register(collection: transactionController)

}
