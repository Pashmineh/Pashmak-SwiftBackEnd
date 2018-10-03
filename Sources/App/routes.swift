import Vapor

/// Register your application's routes here.
public func routes(_ router: Router) throws {

  
  let userRoutes = UserRouteCollection()
  try router.register(collection: userRoutes)
  
  let addressRoutes = AddressRouteCollection()
  try router.register(collection: addressRoutes)
  
  let eventRoutes = EventRouteCollection()
  try router.register(collection: eventRoutes)
  
  let transactionController = TransacrionRouteCollection()
  try router.register(collection: transactionController)

  
  // MARK: - Checkin
  let checkinController = CheckinController()
  let bearerCheckin = router.grouped(Models.User.tokenAuthMiddleware())
  bearerCheckin.post("checkin", use: checkinController.create)
  bearerCheckin.get("checkins", use: checkinController.getAll)
  bearerCheckin.get("checkin", Checkin.parameter, use: checkinController.getCheckin)
  
 
  
}
