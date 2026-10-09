   NEW="FlexToolCode"   # quello che hai ottenuto
   git remote set-url origin "https://github.com/$NEW/keys.git"
   sed -i '' -e "s#github.com/[^/]*/keys.git#github.com/$NEW/keys.git#g" README.md
   grep -n 'git clone' README.md
   git commit -am "Update clone URLs" && git push
   gh auth status   # deve mostrare il nuovo username
