extends Label

var displayed_score := 0

func _process(delta):
	if displayed_score < Global.score:
		# Smooth increment toward actual score
		displayed_score += min(100 * delta, Global.score - displayed_score)
		text = "COINS: " + str(int(displayed_score))
	elif Global.pending_score > 0:
		Global.score += 1
		Global.pending_score -= 1
