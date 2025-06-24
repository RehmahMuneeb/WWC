extends Node
# Banner Ad Singleton - Always visible, auto-loading

var ad_view : AdView
var ad_listener := AdListener.new()
var ad_position := AdPosition.Values.BOTTOM  # Default position

func _ready():
	if not Engine.has_singleton("AdMob"):
		push_error("AdMob plugin not loaded! Check Android/iOS export settings.")
		return
	
	setup_ad_listener()
	initialize_banner()

func setup_ad_listener():
	ad_listener.on_ad_loaded = func():
		print("Banner ad loaded")
		ad_view.show()  # Auto-show when loaded
		
	ad_listener.on_ad_failed_to_load = func(error : LoadAdError):
		push_error("Ad failed: ", error.message)
		# Retry after 30 seconds
		await get_tree().create_timer(30.0).timeout
		ad_view.load_ad(AdRequest.new())

func initialize_banner():
	var ad_size = AdSize.get_current_orientation_anchored_adaptive_banner_ad_size(AdSize.FULL_WIDTH)
	ad_view = AdView.new("ca-app-pub-3940256099942544/2934735716", ad_size, ad_position)  # Replace with your ID
	ad_view.ad_listener = ad_listener
	
	# Configure ad request (simplified from sample)
	var request := AdRequest.new()
	ad_view.load_ad(request)

# Call these from game scripts if needed
func change_position(new_position: AdPosition.Values):
	ad_position = new_position
	if ad_view:
		ad_view.set_position(new_position)

# Handle app pause/resume
func _notification(what):
	if not ad_view: return
	match what:
		NOTIFICATION_APPLICATION_PAUSED:
			ad_view.pause()
		NOTIFICATION_APPLICATION_RESUMED:
			ad_view.resume()
