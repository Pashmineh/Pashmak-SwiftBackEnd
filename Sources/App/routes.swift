import Vapor

/// Register your application's routes here.
public func routes(_ router: Router) throws {

  
  let userRoutes = UserRouteCollection()
  try router.register(collection: userRoutes)
    
  let eventController = EventController()


  let bearerEvent = router.grouped(Models.User.tokenAuthMiddleware())
  bearerEvent.post("event", use: eventController.create)

  let checkinController = CheckinRouteCollection()
  try router.register(collection: checkinController)

  let transactionController = TransacrionRouteCollection()
  try router.register(collection: transactionController)

}
