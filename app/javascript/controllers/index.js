// Import and register all your controllers from the importmap via controllers/**/*_controller
import { application } from "controllers/application"
import { eagerLoadControllersFrom } from "@hotwired/stimulus-loading"
import modalController from "controllers/modal_controller"
import themeController from "controllers/theme_controller"
import messagesController from "controllers/messages_controller"

eagerLoadControllersFrom("controllers", application)

application.register("modal", modalController)
application.register("theme", themeController)
application.register("messages", messagesController)
