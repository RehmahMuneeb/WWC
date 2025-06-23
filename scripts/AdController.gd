extends Node
# Profit-Optimized Banner Ads (Always Visible + Auto-Refresh)

var ad_view : AdView
var ad_listener := AdListener.new()
var ad_position := AdPosition.Values.BOTTOM
var last_refresh_time := 0.0
const REFRESH_RATE := 45.0 # Optimal balance between revenue and UX (seconds)
const RETRY_DELAY := 30.0 # Seconds before retrying failed loads

func _ready():
	if not Engine.has_singleton("AdMob"):
		push_error("AdMob plugin not loaded! Check export settings.")
		return
	
	setup_ad_listener()
	initialize_banner()
	start_refresh_timer()

func setup_ad_listener():
	ad_listener.on_ad_loaded = func():
		last_refresh_time = Time.get_unix_time_from_system()
		ad_view.show()
		print("Banner refreshed at: ", Time.get_time_string_from_system())
		
	ad_listener.on_ad_failed_to_load = func(error : LoadAdError):
		push_error("Ad failed: ", error.message)
		await get_tree().create_timer(RETRY_DELAY).timeout
		load_banner()

func initialize_banner():
	var ad_size = AdSize.get_current_orientation_anchored_adaptive_banner_ad_size(AdSize.FULL_WIDTH)
	ad_view = AdView.new("ca-app-pub-3940256099942544/2934735716", ad_size, ad_position)
	ad_view.ad_listener = ad_listener
	load_banner()

func load_banner():
	var request = AdRequest.new()
	# Revenue optimization techniques:
	request.keywords = ["mobile_game", "premium_content"] # Contextual targeting
	request.content_url = "https://yourgame.com" # URL targeting
	ad_view.load_ad(request)

func start_refresh_timer():
	while true:
		await get_tree().create_timer(5.0).timeout # Check every 5 seconds
		if should_refresh():
			load_banner()

func should_refresh() -> bool:
	return Time.get_unix_time_from_system() - last_refresh_time >= REFRESH_RATE

func change_position(new_position: AdPosition.Values):
	ad_position = new_position
	if ad_view:
		ad_view.set_position(new_position)
		ad_view.show() # Force redraw in new position

func _notification(what):
	if not ad_view: return
	match what:
		NOTIFICATION_APPLICATION_PAUSED:
			ad_view.pause()
		NOTIFICATION_APPLICATION_RESUMED:
			ad_view.resume()
			# Ensure banner reappears after resume
			if should_refresh():
				load_banner()
			else:
				ad_view.show()
