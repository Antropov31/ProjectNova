$ErrorActionPreference = "Stop"
$p = "C:\Users\Antropov31\Desktop\ProjectNova\scripts\game.gd"
$t = [IO.File]::ReadAllText($p)

function Sub([string]$old, [string]$new) {
	if ($script:t.Contains($old)) {
		$script:t = $script:t.Replace($old, $new)
		Write-Output ("OK   : " + $old.Substring(0, [Math]::Min(46, $old.Length)))
	} else {
		Write-Output ("MISS : " + $old.Substring(0, [Math]::Min(46, $old.Length)))
	}
}

Sub "func _ready() -> void:" "var dlg_t0 := 0.0`r`nvar event_seen: Dictionary = {}`r`nvar lore_idx := 0`r`n`r`nfunc _ready() -> void:"

Sub "func _render_dialog() -> void:" "func _render_dialog() -> void:`r`n`tdlg_t0 = menu_t"

Sub "`tvar line: String = dialog_lines[dialog_idx]" "`tvar _dl: String = dialog_lines[dialog_idx]`r`n`tvar _bd: String = Portraits.strip_prefix(_dl)`r`n`tvar _cn: int = clampi(int((menu_t - dlg_t0) * 34.0), 0, _bd.length())`r`n`tPortraits.dialogue(self, _dl, _bd.substr(0, _cn), (nova != null and nova.infected))`r`n`treturn`r`n`tvar line: String = dialog_lines[dialog_idx]"

Sub "`t_draw_lighting()" "`tExtras.draw_decor(self, (room_pos.x*73856093)^(room_pos.y*19349663)^(ng_plus*915))`r`n`t_draw_lighting()"

Sub "`t`t_room_enter_chatter()" "`t`t_room_enter_chatter()`r`n`t`tExtras.random_event(self)"

Sub "`tdraw_rect(Rect2(ic.x-1.5, ic.y-1.5, 3, 3), Color(1,1,1,0.9))" "`tdraw_rect(Rect2(ic.x-1.5, ic.y-1.5, 3, 3), Color(1,1,1,0.9))`r`n`tvar _nm: String = str(off[`"name`"])`r`n`tvar _nw: float = _nm.length() * 3.2`r`n`tdraw_rect(Rect2(b.x + TILE*0.5 - _nw*0.5 - 1.0, b.y - 8.0, _nw + 2.0, 7.0), Color(0.03,0.06,0.09,0.85))`r`n`tdraw_string(font, Vector2(b.x + TILE*0.5 - _nw*0.5, b.y - 2.5), _nm, HORIZONTAL_ALIGNMENT_LEFT, -1, 5, Color(0.8,1.0,0.85))"

$enc = New-Object System.Text.UTF8Encoding($false)
[IO.File]::WriteAllText($p, $t, $enc)
Write-Output "WROTE game.gd"
