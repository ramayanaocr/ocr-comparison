#!/bin/bash
# original script by J Klein <jetmonk@gmail.com> - https://pastebin.com/gNLvXkiM
# based on https://github.com/tesseract-ocr/tesseract/wiki/TrainingTesseract-4.00#fine-tuning-for--a-few-characters

################################################################
# variables to set tasks performed
MakeTraining=yes
MakeEval=yes
RunTraining=yes
BuildFinalTrainedFile=yes
################################################################

# Language
Lang=san
Continue_from_lang=san

# Number of Iterations
MaxIterations=3000

# directory with training scripts - tesstrain.sh etc.
# this is not the usual place-  because they are not installed by default
tesstrain_dir=../../tesseract/src/training

# directory with the old 'best' training set
#bestdata_dir=../tesseract/tessdata
#bestdata_dir=../../tessdata_best
bestdata_dir=/home/sarthak/tessdata_best

# downloaded directory with language data -
# Modify wordlists etc as needed
langdata_dir=../langdata

# IMPORTANT - 
# Copy 100-120 lines from $langdata_dir/$Lang/$Lang.training_text 
# as max 3 pages of training text is used; copy to a new file
# $langdata_dir/$Lang/$Lang.plus.training_text
# ADD about 15 instances per every new char to be added to it
plusTraining_text=training_text
echo $langdata_dir/$Lang/$Lang.$plusTraining_text
# fonts directory for this system
fonts_dir=../fonts

# fonts to use for training - a minimal set for fast tests
fonts_for_training="'chandas'"
 
# fonts for computing evals of best fit model
fonts_for_eval="'samanata'"

# output directories for this run
train_output_dir=./trained_plus_chars_$Continue_from_lang
eval_output_dir=./eval_plus_chars_$Continue_from_lang

# the output trained data file to drop into tesseract
final_trained_data_file=$train_output_dir/$Lang-FAST.traineddata

# fatal bug workaround for pango
#export PANGOCAIRO_BACKEND=fc 

if [ $MakeTraining = "yes" ]; then

  echo "###### MAKING TRAINING DATA ######"
  rm -rf $train_output_dir
  mkdir $train_output_dir
 
  echo "#### run tesstrain.sh ####"
  
# the EVAL handles the quotes in the font list
eval $tesstrain_dir/tesstrain.sh \
   --lang $Lang \
   --linedata_only\
   --noextract_font_properties \
   --exposures "0" \
   --fonts_dir $fonts_dir \
   --fontlist $fonts_for_training \
   --langdata_dir $langdata_dir \
   --tessdata_dir  $bestdata_dir \
   --training_text $langdata_dir/$Lang/$Lang.$plusTraining_text \
   --output_dir $train_output_dir

fi

# at this point, $train_output_dir should have $Lang.FontX.exp0.lstmf
# and $Lang.training_files.txt

# eval data
if [ $MakeEval = "yes" ]; then
  echo "###### MAKING EVAL DATA ######"
  rm -rf $eval_output_dir
  mkdir $eval_output_dir
  
eval $tesstrain_dir/tesstrain.sh \
   --fonts_dir $fonts_dir\
   --fontlist $fonts_for_eval \
   --lang $Lang \
   --linedata_only \
   --noextract_font_properties \
   --langdata_dir $langdata_dir \
   --tessdata_dir  $bestdata_dir \
   --training_text $langdata_dir/$Lang/$Lang.$plusTraining_text \
   --output_dir $eval_output_dir
 
fi

# at this point, $eval_output_dir should have similar files as
# $train_output_dir but for different font set

if [ $RunTraining = "yes" ]; then

echo "#### combine_tessdata to extract lstm model from 'tessdata_best' for $Continue_from_lang ####"
  
  combine_tessdata \
   -u $bestdata_dir/$Continue_from_lang.traineddata \
    $train_output_dir/$Continue_from_lang.

echo "#### build version string ####"
   Version_Str="$Lang Replace Layer on $(date +%F) from "
   sed -e "s/^/$Version_Str/" $train_output_dir/$Continue_from_lang.version > $train_output_dir/$Lang.new.version

echo "#### merge unicharsets to ensure all existing chars are included ####"
merge_unicharsets \
   $train_output_dir/$Continue_from_lang.lstm-unicharset \
   $train_output_dir/$Lang/$Lang.unicharset \
   $train_output_dir/$Lang.unicharset
   
echo "#### rebuild starter traineddata ####"
# Add these flags to the command below, as needed
#  --lang_is_rtl  True \
#  --pass_through_recoder True \
#
combine_lang_model \
  --input_unicharset $train_output_dir/$Lang.unicharset \
  --script_dir $langdata_dir \
  --words $langdata_dir/$Lang/$Lang.wordlist \
  --numbers $langdata_dir/$Lang/$Lang.numbers \
  --puncs $langdata_dir/$Lang/$Lang.punc \
  --output_dir $train_output_dir \
  --lang $Lang \
  --version_str $train_output_dir/$Lang.new.version 
  
echo "#### training from $bestdata_dir/$Continue_from_lang.traineddata #####"
  
lstmtraining \
  --continue_from  $train_output_dir/$Continue_from_lang.lstm \
  --traineddata   $train_output_dir/$Lang/$Lang.traineddata \
  --append_index 5 --net_spec '[Lfx256 O1c111]' \
  --max_iterations $MaxIterations \
  --debug_interval -1 \
  --train_listfile $train_output_dir/$Lang.training_files.txt \
  --model_output  $train_output_dir/replacelayer 
 
lstmeval \
  --model $train_output_dir/replacelayer_checkpoint \
  --traineddata   $train_output_dir/$Lang/$Lang.traineddata \
  --eval_listfile $eval_output_dir/$Lang.training_files.txt
 
fi


if [ $BuildFinalTrainedFile = "yes" ] ; then
  echo "#### Building final trained file $final_trained_data_file d####"
  
  lstmtraining \
  --stop_training \
  --convert_to_int \
  --continue_from $train_output_dir/replacelayer_checkpoint \
  --traineddata $train_output_dir/$Lang/$Lang.traineddata \
  --model_output $final_trained_data_file

fi

# now $final_trained_data_file is substituted for installed


