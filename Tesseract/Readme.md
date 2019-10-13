# Table of Contents
1. [Tesseract](#Tesseract)
2. [Training with Tesseract 4.00](#Training)
    1. [Running shell script for fine tuning](#finetuning)
    2. [Running shell script for top layer removal](#toplayer)
    3. [Training from scratch](#scratch)
    

## Tesseract <a name="Tesseract"></a>
-	It is an open source Optical Character Recognition(OCR) engine initially developed by HP and then research on it is carried out by Google from 2006.
-	Refer this paper by Ray Smith, Google Inc. 
https://github.com/tesseract-ocr/docs/blob/master/tesseracticdar2007.pdf
-   It has support for around 116 languages.
-	Tesseract 4.00 includes a new neural network-based recognition engine that delivers significantly higher accuracy (on document images) than the previous versions, in return for a significant increase in required compute power.  
https://github.com/tesseract-ocr/tesseract/wiki/TrainingTesseract-4.00 
-	It is available for 
    -   Linux and  Mac OS X: https://github.com/tesseract-ocr/tesseract
    -   Windows: https://github.com/UB-Mannheim/tesseract

## Training with Tesseract 4.00 <a name="Training"></a>

## Workflow
![](tesseract_workflow.png?raw=true) 

https://www.endpoint.com/blog/2018/07/09/training-tesseract-models-from-scratch
-   Environment used
    -   VM instance: Google Cloud Platform
        (8 vCPUs, 16 GB memory)
    -	OS: Ubuntu 18.04 LTS (Requires Superuser rights)
    -	Softwares: apt-get installer, git, tesseract, ruby
    
-   Build additional libraries (Training tools)
    -   https://github.com/tesseract-ocr/tesseract/wiki/Compiling-%E2%80%93-GitInstallation
    -   sudo apt-get install libicu-dev libpango1.0-dev libcairo2-dev libleptonica-dev wdiff

-   Clone from github
    git clone https://github.com/tesseract-ocr/tesseract.git

-   Finally, run these:
        cd tesseract
        ./autogen.sh
        ./configure
        make (This takes time)
        sudo make install
        sudo ldconfig
        make training
        sudo make training-install

-   Create lstmf files
    -   Shell
    tesseract /home/sarthak/projects/tesseract/tessdata/tessdata_ramayana/ram023.tif /home/sarthak/projects/tesseract/tessdata/tessdata_ramayana/ram023.box --tessdata-dir /home/sarthak/projects/tesseract/tessdata/ -l Devanagari lstm.train

    -   Windows
    tesseract "D:\Data\CaseStudies-1\tessdata_ramayana\ram023.tif" "D:\Data\CaseStudies-1\tessdata_ramayana\ram023.box" --tessdata-dir "D:\Softwares\OCR\Tesseract-OCR\tessdata" -l script/Devanagari lstm.train


-   Make an eval file for testing
    -   ram-eval.gt.txt
    -   ram-eval.png
    -   ram-eval.tif
    -   ram-eval.box

There are multiple options for training:

-   Fine tune. Starting with an existing trained language, train on your specific additional data. This may work for problems that are close to the existing training data, but different in some subtle way, like a particularly unusual font. May work with even a small amount of training data.

-   Cut off the top layer (or some arbitrary number of layers) from the network and retrain a new top layer using the new data. If fine tuning doesn't work, this is most likely the next best option. Cutting off the top layer could still work for training a completely new language or script, if you start with the most similar looking script.

-   Retrain from scratch. This is a daunting task, unless you have a very representative and sufficiently large training set for your problem. If not, you are likely to end up with an over-fitted network that does really well on the training data, but not on the actual data.

## 1. Running shell script for fine tuning <a name="finetuning"></a>
NKP training
https://github.com/Shreeshrii/tessdata_sanskrit
https://groups.google.com/forum/#!msg/tesseract-ocr/NNZ7GOBLB_8/IMqn2IgzAwAJ
https://www.youtube.com/watch?v=TpD76k2HYms&t=456s
https://github.com/tesseract-ocr/tessdata_best
https://medium.com/datadriveninvestor/review-for-tesseract-and-kraken-ocr-for-text-recognition-2e63c2adedd0
cp script /usr/local/share/tessdata/
sh ram.sh 2>&1 | tee 31_08_train.log

##  2.  Running shell script for top layer removal <a name="toplayer"></a>
https://github.com/tesseract-ocr/tesseract/issues/1382
-   use tesstrain_replacelayer.sh.txt
 
-   use sudo to run the script
Error for eng.traineddata not found
https://github.com/tesseract-ocr/tessdata/blob/master/eng.traineddata

Add radical-stroke.txt to the langdata folder

##  3. Training from scratch <a name="scratch"></a>
https://github.com/Shreeshrii/tess4training/blob/master/2-scratch.sh
https://www.endpoint.com/blog/2018/07/09/training-tesseract-models-from-scratch

### Generating the unicharset file <a name="unicharset"></a>
You’ll need to install the unicode-scripts and unicode-categories gems first. The usage is as it stands in the source code:
sudo gem install unicode-scripts
sudo gem install unicode-categories
ruby extract_unicharset.rb path/to/all-boxes > path/to/unicharset

USE box files from jtesseditor NOT wordstr generated by lstm.train

### move all box files to single file
cat /home/sarthak/projects/tessdata_sanskrit/allboxes/*.box > /home/sarthak/projects/tessdata_sanskrit/tesstrain_scratch/all-boxes

### extract unicharset
ruby extract_unicharset.rb /home/sarthak/projects/tessdata_sanskrit/tesstrain_scratch/all-boxes > /home/sarthak/projects/tessdata_sanskrit/tesstrain_scratch/deva_new.unicharset

Combining images with box files into *.lstmf files
#### cd to folder containing .lstmf files
ls -1 *.lstmf | sort -R > all-lstmf

### move to folder tesstrain_scratch
mv all-lstmf ../tesstrain_scratch/Generating the training and evaluation files lists

### Generating the training and evaluation files lists
head -n 55 /home/sarthak/projects/tessdata_sanskrit/tesstrain_scratch/all-lstmf > list.train
tail -n +56 /home/sarthak/projects/tessdata_sanskrit/tesstrain_scratch/all-lstmf > list.eval
Compiling the initial *.traineddata file

### Compiling the initial *.traineddata file
mkdir tesstrain_scratch

combine_lang_model \
  --input_unicharset /home/sarthak/projects/tessdata_sanskrit/tesstrain_scratch/deva_new.unicharset \
  --script_dir /home/sarthak/projects/tesseract/tessdata \
  --output_dir /home/sarthak/projects/tessdata_sanskrit/tesstrain_scratch/tessdata_scratch \
  --pass_through_recoder --lang san_scratch

#### Error  
Failed to read data from: /home/sarthak/projects/tesseract/tessdata/san_scratch/san_scratch.config
Failed to read data from: /home/sarthak/projects/tesseract/tessdata/radical-stroke.txt
Error reading radical code table /home/sarthak/projects/tesseract/tessdata/radical-stroke.txt

Solve by moving san.config from tessdata san directory
and radical-stroke.txt from langdata to the dir
Starting the actual training process

num_classes=`head -n1 /home/sarthak/projects/tessdata_sanskrit/tesstrain_scratch/tessdata_scratch/san_scratch/san_scratch.unicharset`

### Run Training
#### Run where the lstmf files  are present

#### with num_classes
lstmtraining \
  --traineddata /home/sarthak/projects/tessdata_sanskrit/tesstrain_scratch/tessdata_scratch/san_scratch/san_scratch.traineddata \
  --net_spec "[1,40,0,1 Ct5,5,64 Mp3,3 Lfys128 Lbx256 Lbx256 O1c$num_classes]" \
  --model_output /home/sarthak/projects/tessdata_sanskrit/tesstrain_scratch/tessdata_scratch/model \
  --train_listfile /home/sarthak/projects/tessdata_sanskrit/tesstrain_scratch/list.train \
  --eval_listfile /home/sarthak/projects/tessdata_sanskrit/tesstrain_scratch/list.eval

#### with 92 hardcoded
lstmtraining   --traineddata /home/sarthak/projects/tessdata_sanskrit/tesstrain_scratch/tessdata_scratch/san_scratch/san_scratch.traineddata   --net_spec "[1,40,0,1 Ct5,5,64 Mp3,3 Lfys128 Lbx256 Lbx256 O1c92]"   --model_output /home/sarthak/projects/tessdata_sanskrit/tesstrain_scratch/tessdata_scratch/model   --train_listfile /home/sarthak/projects/tessdata_sanskrit/tesstrain_scratch/list.train   --eval_listfile /home/sarthak/projects/tessdata_sanskrit/tesstrain_scratch/list.eval  
