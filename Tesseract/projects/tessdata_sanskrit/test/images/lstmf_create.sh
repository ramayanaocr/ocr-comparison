for file in *.png; do
  echo $file
  base=`basename $file .png`
  tesseract $file $base -l script/Devanagari --dpi 300 lstm.train
done
