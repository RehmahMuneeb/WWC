extends Node

# Signals
signal banner_loaded
signal banner_failed(error: String)
signal interstitial_loaded
signal interstitial_failed(error: String)
signal interstitial_closed
signal rewarded_loaded
signal rewarded_failed(error: String)
signal reward_earned(amount: int, type: String)
signal rewarded_closed

# Configuration - REPLACE WITH YOUR ACTUAL AD UNIT IDs
const ANDROID_AD_UNITS = {
	"banner": "ca-app-pub-3940256099942544/6300978111", # Test ID
	"interstitial": "ca-app-pub-3940256099942544/1033173712", # Test ID
	"rewarded": "ca-app-pub-3940256099942544/5224354917" # Test ID
}

# Ad References
var _banner_ad: AdView
var _interstitial_ad: InterstitialAd
var _rewarded_ad: RewardedAd

# Callbacks
var _banner_listener := AdListener.new()
var _interstitial_callback := InterstitialAdLoadCallback.new()
var _rewarded_callback := RewardedAdLoadCallback.new()
var _fullscreen_callback := FullScreenContentCallback.new()
var _reward_listener := OnUserEarnedRewardListener.new()

func _ready() -> void:
	# Initialize MobileAds SDK
	MobileAds.initialize()
	
	# Setup callbacks
	_setup_banner_listener()
	_setup_interstitial_callbacks()
	_setup_rewarded_callbacks()

#region Initialization
func _setup_banner_listener() -> void:
	_banner_listener.on_ad_loaded = func() -> void:
		banner_loaded.emit()
	_banner_listener.on_ad_failed_to_load = func(error: LoadAdError) -> void:
		banner_failed.emit(error.message)

func _setup_interstitial_callbacks() -> void:
	_interstitial_callback.on_ad_loaded = func(ad: InterstitialAd) -> void:
		_interstitial_ad = ad
		_interstitial_ad.full_screen_content_callback = _fullscreen_callback
		interstitial_loaded.emit()
	_interstitial_callback.on_ad_failed_to_load = func(error: LoadAdError) -> void:
		interstitial_failed.emit(error.message)

func _setup_rewarded_callbacks() -> void:
	_rewarded_callback.on_ad_loaded = func(ad: RewardedAd) -> void:
		_rewarded_ad = ad
		_rewarded_ad.full_screen_content_callback = _fullscreen_callback
		rewarded_loaded.emit()
	_rewarded_callback.on_ad_failed_to_load = func(error: LoadAdError) -> void:
		rewarded_failed.emit(error.message)
	
	_fullscreen_callback.on_ad_dismissed_full_screen_content = func() -> void:
		if _interstitial_ad:
			interstitial_closed.emit()
			load_interstitial()
		elif _rewarded_ad:
			rewarded_closed.emit()
			load_rewarded()
	
	_reward_listener.on_user_earned_reward = func(reward: RewardedItem) -> void:
		reward_earned.emit(reward.amount, reward.type)
#endregion

#region Banner Ads
func load_banner(position: int = AdPosition.Values.BOTTOM) -> void:
	if _banner_ad:
		_banner_ad.destroy()
	
	_banner_ad = AdView.new(ANDROID_AD_UNITS["banner"], AdSize.BANNER, position)
	_banner_ad.ad_listener = _banner_listener
	_banner_ad.load_ad(AdRequest.new())

func show_banner() -> void:
	if _banner_ad:
		_banner_ad.show()

func hide_banner() -> void:
	if _banner_ad:
		_banner_ad.hide()

func destroy_banner() -> void:
	if _banner_ad:
		_banner_ad.destroy()
		_banner_ad = null
#endregion

#region Interstitial Ads
func load_interstitial() -> void:
	if _interstitial_ad:
		_interstitial_ad.destroy()
	
	InterstitialAdLoader.new().load(
		ANDROID_AD_UNITS["interstitial"],
		AdRequest.new(),
		_interstitial_callback
	)

func show_interstitial() -> void:
	if _interstitial_ad:
		_interstitial_ad.show()
	else:
		interstitial_failed.emit("No ad loaded")
		load_interstitial()
#endregion

#region Rewarded Ads
func load_rewarded() -> void:
	if _rewarded_ad:
		_rewarded_ad.destroy()
	
	RewardedAdLoader.new().load(
		ANDROID_AD_UNITS["rewarded"],
		AdRequest.new(),
		_rewarded_callback
	)

func show_rewarded() -> void:
	if _rewarded_ad:
		_rewarded_ad.show(_reward_listener)
	else:
		rewarded_failed.emit("No ad loaded")
		load_rewarded()
#endregion

func _notification(what: int) -> void:
	# Clean up when exiting
	if what == NOTIFICATION_PREDELETE:
		destroy_banner()
		if _interstitial_ad:
			_interstitial_ad.destroy()
		if _rewarded_ad:
			_rewarded_ad.destroy() 
