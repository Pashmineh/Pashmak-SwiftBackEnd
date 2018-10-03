import Vapor

/// Register your application's routes here.
public func routes(_ router: Router) throws {

  
  let userRoutes = UserRouteCollection()
  try router.register(collection: userRoutes)
  
  let addressRoutes = AddressRouteCollection()
  try router.register(collection: addressRoutes)
  
  let eventRoutes = EventRouteCollection()
  try router.register(collection: eventRoutes)
  
  let transactionRoutes = TransacrionRouteCollection()
  try router.register(collection: transactionRoutes)

  let checkinRoutes = CheckinRouteCollection()
  try router.register(collection: checkinRoutes)

  let messageRoutes = MessageRouteCollection()
  try router.register(collection: messageRoutes)

}
