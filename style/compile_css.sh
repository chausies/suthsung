# rm main.min.css
# rm temp.css
lessc main.less temp.css
purifycss temp.css ../suthsung.html ../html/*.html ../scripts/suthsung.min.js --min --out main.min.css
rm temp.css
