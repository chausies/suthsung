# Compile all coffeescript, minify it, and put it suthsung.min.js
set -e
if [ -f suthsung.min.js ]; then
   mv suthsung.min.js delete_this
fi
coffee -c *.coffee
uglifyjs main.js *.js -cmo temp.js
# cat *.js >> temp.js
mv temp.js temp
rm *.js
mv temp suthsung.min.js
if [ -f delete_this ]; then
  rm delete_this
fi
