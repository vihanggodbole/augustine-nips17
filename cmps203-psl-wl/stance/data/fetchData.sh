if [ -d "4forums" ]; then
      echo "Experiments data folder found cached; skipping download."
      return
fi

wget https://linqs-data.soe.ucsc.edu/public/all_forums_data.zip
unzip all_forums_data.zip
rm *.zip
rm -rf __MACOSX
