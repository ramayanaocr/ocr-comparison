#!/bin/bash
rm -rf build
mkdir build
my_files=$(ls tessdata_ramayana/*.png )
 for my_file in ${my_files}; do
    f=${my_file%.*}
    echo $f 
    #time tesseract $f.png        $f -l script/Devanagari --psm 6 --dpi 300 wordstrbox
    time tesseract $f.png        $f -l script/Devanagari --dpi 300 wordstrbox
	mv "$f.box" "$f.wordstrbox" 
    sed -i -e "s/ \#.*/ \#/g"  "$f.wordstrbox"
    sed -e '/^$/d' "$f.gt.txt" > build/tmp.txt
    sed -e  's/$/\n/g' build/tmp.txt > "$f.gt.txt"
    paste --delimiters="\0"  "$f.wordstrbox"  "$f.gt.txt" > "$f.box"
    rm "$f.wordstrbox" build/tmp.txt
    #time tesseract "$f.png"        "$f"  -l script/Devanagari  --psm 6 --dpi 300 lstm.train
	time tesseract "$f.png"        "$f"  -l script/Devanagari  --dpi 300 lstm.train
 done

combine_tessdata -u ~/tessdata_best/script/Devanagari.traineddata ~/tessdata_best/script/Devanagari.

ls -1 tessdata_ramayana/*.lstmf  > build/san.ram.training_files.txt
sed -i -e '/eval/d' build/san.ram.training_files.txt
ls -1 tessdata_ramayana/*eval*.lstmf >  build/san.ram_eval.training_files.txt

rm build/*checkpoint  ram*.traineddata

# review the console output with debug_level -1 for 100 iterations
# if there are glaring differences in OCR output and groundtruth, review the Wordstr box files

lstmtraining \
  --model_output build/ram \
  --continue_from  ~/tessdata_best/script/Devanagari.lstm \
  --traineddata ~/tessdata_best/script/Devanagari.traineddata \
  --train_listfile  build/san.ram.training_files.txt \
  --debug_interval -1 \
  --max_iterations 100

# eval error is minimum at 700 iterations

for num_iterations in {300..700..100}; do

lstmtraining \
  --model_output build/ram \
  --continue_from  ~/tessdata_best/script/Devanagari.lstm \
  --traineddata ~/tessdata_best/script/Devanagari.traineddata \
  --train_listfile  build/san.ram.training_files.txt \
  --debug_interval 0 \
  --max_iterations $num_iterations
  
lstmtraining \
  --stop_training \
  --continue_from build/ram_checkpoint \
  --traineddata ~/tessdata_best/script/Devanagari.traineddata \
  --model_output san_ram.traineddata

lstmeval \
  --verbosity -1 \
  --model san_ram.traineddata \
  --eval_listfile build/san.ram_eval.training_files.txt 

done

time tesseract tessdata_ramayana/ram-eval.png build/ram-eval -l san_ram --tessdata-dir ./ --psm 6 --dpi 300
wdiff -3 -s  tessdata_ramayana/ram-eval.gt.txt  build/ram-eval.txt 

echo "Convert to Integer Model"

lstmtraining \
  --stop_training \
  --convert_to_int \
  --continue_from build/ram_checkpoint \
  --traineddata ~/tessdata_best/script/Devanagari.traineddata \
  --model_output san_ram_int.traineddata

lstmeval \
  --verbosity -1 \
  --model san_ram_int.traineddata \
  --eval_listfile build/san.ram_eval.training_files.txt 
  
time tesseract tessdata_ramayana/ram-eval.png build/ram_int-eval -l san_ram_int --tessdata-dir ./ --psm 6 --dpi 300
wdiff -3 -s  tessdata_ramayana/ram-eval.gt.txt  build/ram_int-eval.txt 

echo "Compare with Devanagari"

lstmeval \
  --verbosity -1 \
  --model ~/tessdata_best/script/Devanagari.traineddata \
  --eval_listfile build/san.ram_eval.training_files.txt 

time tesseract tessdata_ramayana/ram-eval.png build/ram-eval-deva -l script/Devanagari  --psm 6  --dpi 300
wdiff -3 -s  tessdata_ramayana/ram-eval.gt.txt  build/ram-eval-deva.txt 

echo "Compare with Sanskrit"

lstmeval \
  --verbosity -1 \
  --model ~/tessdata_best/san.traineddata \
  --eval_listfile build/san.ram_eval.training_files.txt 
  
time tesseract tessdata_ramayana/ram-eval.png build/ram-eval-san -l san  --psm 6  --dpi 300
wdiff -3 -s  tessdata_ramayana/ram-eval.gt.txt  build/ram-eval-san.txt