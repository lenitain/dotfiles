# ds：重启 dsh 的 zmx 会话（存在就 kill，再后台起一个）。

ds() {
    if zmx list 2>/dev/null | grep -q $'^[[:blank:]]*name=dsh\t'; then
        zmx kill dsh
    fi
    zmx run dsh -d dsh web --no-open
}
