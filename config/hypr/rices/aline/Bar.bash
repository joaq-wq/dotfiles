# This file launch the bar/s
for mon in $(polybar --list-monitors | cut -d":" -f1); do
	MONITOR=$mon polybar -q aline-bar -c "${HOME}"/.config/hypr/rices/"${RICE}"/config.ini &
done
