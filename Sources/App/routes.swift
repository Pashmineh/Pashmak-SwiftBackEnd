import Vapor

/// Register your application's routes here.
public func routes(_ router: Router) throws {

  let userController = UserController()
  let debtController = DebtController()
  let eventController = EventController()
  
  router.post("register", use: userController.create)
  router.post("authenticate", use: userController.login)
  
  let bearerUser = router.grouped(Models.User.tokenAuthMiddleware())
  bearerUser.get("profile", use: userController.profile)
  bearerUser.get("redis", use: userController.redis)
  bearerUser.get("logout", use: userController.logout)
  
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


}
