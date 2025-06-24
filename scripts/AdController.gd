extends Node
# Ad Controller Singleton - Handles all ad types

# Banner Ad Variables
var ad_view : AdView
var ad_listener := AdListener.new()
var ad_position := AdPosition.Values.BOTTOM  # Default position

# Interstitial Ad Variables
var interstitial_ad : InterstitialAd
var interstitial_ad_load_callback := InterstitialAdLoadCallback.new()
var interstitial_full_screen_content_callback := FullScreenContentCallback.new()

# Rewarded Ad Variables
var rewarded_ad : RewardedAd
var rewarded_ad_load_callback := RewardedAdLoadCallback.new()
var rewarded_full_screen_content_callback := FullScreenContentCallback.new()

# Test Ad Unit IDs (Replace with your real ones before publishing)
const BANNER_AD_ID = "ca-app-pub-3940256099942544/2934735716"  # Test banner ID
const INTERSTITIAL_AD_ID = "ca-app-pub-3940256099942544/1033173712"  # Test interstitial ID
const REWARDED_AD_ID = "ca-app-pub-3940256099942544/5224354917"  # Test rewarded ID

func _ready():
	if not Engine.has_singleton("AdMob"):
		push_error("AdMob plugin not loaded! Check Android/iOS export settings.")
		return
	
	setup_ad_listener()
	initialize_banner()
	setup_interstitial_callbacks()
	setup_rewarded_callbacks()
	load_interstitial_ad()
	load_rewarded_ad()

# Banner Ad Functions
func setup_ad_listener():
	ad_listener.on_ad_loaded = func():
		print("Banner ad loaded")
		ad_view.show()  # Auto-show when loaded
		
	ad_listener.on_ad_failed_to_load = func(error : LoadAdError):
		push_error("Banner ad failed: ", error.message)
		# Retry after 30 seconds
		await get_tree().create_timer(30.0).timeout
		ad_view.load_ad(AdRequest.new())

func initialize_banner():
	var ad_size = AdSize.get_current_orientation_anchored_adaptive_banner_ad_size(AdSize.FULL_WIDTH)
	ad_view = AdView.new(BANNER_AD_ID, ad_size, ad_position)
	ad_view.ad_listener = ad_listener
	
	var request := AdRequest.new()
	ad_view.load_ad(request)

# Interstitial Ad Functions
func setup_interstitial_callbacks():
	interstitial_ad_load_callback.on_ad_failed_to_load = func(adError : LoadAdError) -> void:
		print("Interstitial failed to load: ", adError.message)
		# Retry after 30 seconds
		await get_tree().create_timer(30.0).timeout
		load_interstitial_ad()
	
	interstitial_ad_load_callback.on_ad_loaded = func(new_interstitial_ad : InterstitialAd) -> void:
		print("Interstitial ad loaded")
		interstitial_ad = new_interstitial_ad
		interstitial_ad.full_screen_content_callback = interstitial_full_screen_content_callback
	
	interstitial_full_screen_content_callback.on_ad_dismissed_full_screen_content = func() -> void:
		print("Interstitial ad dismissed")
		load_interstitial_ad()  # Pre-load next interstitial

func load_interstitial_ad():
	InterstitialAdLoader.new().load(INTERSTITIAL_AD_ID, AdRequest.new(), interstitial_ad_load_callback)

func show_interstitial_ad():
	if interstitial_ad:
		interstitial_ad.show()
	else:
		print("No interstitial ad loaded yet")
		load_interstitial_ad()

# Rewarded Ad Functions
func setup_rewarded_callbacks():
	rewarded_ad_load_callback.on_ad_failed_to_load = func(adError : LoadAdError) -> void:
		print("Rewarded failed to load: ", adError.message)
		# Retry after 30 seconds
		await get_tree().create_timer(30.0).timeout
		load_rewarded_ad()
	
	rewarded_ad_load_callback.on_ad_loaded = func(new_rewarded_ad : RewardedAd) -> void:
		print("Rewarded ad loaded")
		rewarded_ad = new_rewarded_ad
		rewarded_ad.full_screen_content_callback = rewarded_full_screen_content_callback
	
	rewarded_full_screen_content_callback.on_ad_dismissed_full_screen_content = func() -> void:
		print("Rewarded ad dismissed")
		load_rewarded_ad()  # Pre-load next rewarded ad

func load_rewarded_ad():
	RewardedAdLoader.new().load(REWARDED_AD_ID, AdRequest.new(), rewarded_ad_load_callback)

func show_rewarded_ad(on_user_earned_reward_callback: Callable, on_ad_failed_callback: Callable = func(): pass):
	if rewarded_ad:
		# Set up the user earned reward callback
		rewarded_ad_load_callback.on_user_earned_reward = func(rewarded_item : RewardedItem) -> void:
			print("Reward earned: ", rewarded_item.type, " amount: ", rewarded_item.amount)
			on_user_earned_reward_callback.call()
		
		# Set up ad failed to show callback
		rewarded_full_screen_content_callback.on_ad_failed_to_show_full_screen_content = func(ad_error : AdError) -> void:
			print("Rewarded ad failed to show: ", ad_error.message)
			on_ad_failed_callback.call()
		
		rewarded_ad.show()
	else:
		print("No rewarded ad loaded yet")
		on_ad_failed_callback.call()
		load_rewarded_ad()

# Handle app pause/resume
func _notification(what):
	if what == NOTIFICATION_APPLICATION_PAUSED:
		if ad_view: ad_view.pause()
	elif what == NOTIFICATION_APPLICATION_RESUMED:
		if ad_view: ad_view.resume()
