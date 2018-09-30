import Vapor

/// Register your application's routes here.
public func routes(_ router: Router) throws {
  
  let userController = UserController()
  let debtController = DebtController()
  
  router.post("register", use: userController.create)
  router.post("authenticate", use: userController.login)
  
  let bearerUser = router.grouped(User.tokenAuthMiddleware())
  bearerUser.get("profile", use: userController.profile)
  bearerUser.get("logout", use: userController.logout)
  
  let bearerDebt = router.grouped(User.tokenAuthMiddleware())
  bearerDebt.post("debts", use: debtController.create)
}
