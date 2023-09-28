#Define path to Subjectlist
SUBJECT_LIST=/Users/uqloestr/Desktop/co-reg/Subjectlist.txt
#Define path to ROIlist
ROI_LIST=/Users/uqloestr/Desktop/co-reg/ROI_list.txt
#Define list of measures
MEASURE_LIST=/Users/uqloestr/Desktop/co-reg/Measureslist.txt
#Define path to ROI output measures files
#volume
OUTPUT_FILE_VTA_VOLUME=/Users/uqloestr/Desktop/co-reg/VTA_volume.txt
OUTPUT_FILE_PAG_VOLUME=/Users/uqloestr/Desktop/co-reg/PAG_volume.txt
OUTPUT_FILE_NTS_VOLUME=/Users/uqloestr/Desktop/co-reg/NTS_volume.txt
OUTPUT_FILE_LC_VOLUME=/Users/uqloestr/Desktop/co-reg/LC_volume.txt
OUTPUT_FILE_DRN_VOLUME=/Users/uqloestr/Desktop/co-reg/DRN_volume.txt
#ICVF
OUTPUT_FILE_VTA_ICVF=/Users/uqloestr/Desktop/co-reg/VTA_ICVF.txt
OUTPUT_FILE_PAG_ICVF=/Users/uqloestr/Desktop/co-reg/PAG_ICVF.txt
OUTPUT_FILE_NTS_ICVF=/Users/uqloestr/Desktop/co-reg/NTS_ICVF.txt
OUTPUT_FILE_LC_ICVF=/Users/uqloestr/Desktop/co-reg/LC_ICVF.txt
OUTPUT_FILE_DRN_ICVF=/Users/uqloestr/Desktop/co-reg/DRN_ICVF.txt
#ISOVF
OUTPUT_FILE_VTA_ISOVF=/Users/uqloestr/Desktop/co-reg/VTA_ISOVF.txt
OUTPUT_FILE_PAG_ISOVF=/Users/uqloestr/Desktop/co-reg/PAG_ISOVF.txt
OUTPUT_FILE_NTS_ISOVF=/Users/uqloestr/Desktop/co-reg/NTS_ISOVF.txt
OUTPUT_FILE_LC_ISOVF=/Users/uqloestr/Desktop/co-reg/LC_ISOVF.txt
OUTPUT_FILE_DRN_ISOVF=/Users/uqloestr/Desktop/co-reg/DRN_ISOVF.txt
#OD
OUTPUT_FILE_VTA_OD=/Users/uqloestr/Desktop/co-reg/VTA_OD.txt
OUTPUT_FILE_PAG_OD=/Users/uqloestr/Desktop/co-reg/PAG_OD.txt
OUTPUT_FILE_NTS_OD=/Users/uqloestr/Desktop/co-reg/NTS_OD.txt
OUTPUT_FILE_LC_OD=/Users/uqloestr/Desktop/co-reg/LC_OD.txt
OUTPUT_FILE_DRN_OD=/Users/uqloestr/Desktop/co-reg/DRN_OD.txt


#initiate loop to cycle through subjects
for subj in $(cat ${SUBJECT_LIST}) ; do

cd /Users/uqloestr/Desktop/co-reg/${subj}

#extract b0s from DWI series (better contrast for co-registration )
dwiextract  data_ud.nii.gz -bzero ${subj}_b0s.nii -fslgrad bvecs bvals -force

#calculate average b0 (need to use 3D instead of 4D image)
mrmath  ${subj}_b0s.nii mean ${subj}_meanb0.nii  -axis 3

#extraxt brain and brain mask
bet2 ${subj}_meanb0.nii ${subj}_b0_brain -f 0.2  -m

#unzip skull-stripped brains (b0 and T1)
gunzip ${subj}_b0_brain.nii.gz
gunzip T1_brain.nii.gz

#register skull-stripped T1 to b0
antsRegistration --verbose 1 --dimensionality 3 --float 0 --output [ants_t12b0,antsWarped_t12b0.nii.gz,antsInverseWarped_t12b0.nii.gz] --interpolation Linear --use-histogram-matching 1 --winsorize-image-intensities [0.005,0.995] --transform Rigid[0.1] --metric CC[${subj}_b0_brain.nii,T1_brain.nii,1,4,Regular,0.1] --convergence [1000x500x250x100,1e-6,10] --shrink-factors 8x4x2x1 --smoothing-sigmas 3x2x1x0vox --transform Affine[0.1] --metric CC[${subj}_b0_brain.nii,T1_brain.nii,1,4,Regular,0.2] --convergence [1000x500x250x100,1e-6,10] --shrink-factors 8x4x2x1 --smoothing-sigmas 3x2x1x0vox --transform SyN[0.1,3,0] --metric CC[${subj}_b0_brain.nii,T1_brain.nii,1,4] --convergence [100x70x50x20,1e-6,10] --shrink-factors 4x2x2x1 --smoothing-sigmas 2x2x1x0vox -x [reference_mask.nii.gz,input_mask.nii.gz]

#generate an identity (deformation field) warp
warpinit T1_brain.nii identity_warp_t12b0[].nii -force

#transform  identity warp
for i in {0..2}; do
antsApplyTransforms -d 3 -e 0 -i identity_warp_t12b0${i}.nii -o mrtrix_warp_t12b0${i}.nii -r ${subj}_b0_brain.nii -t ants_t12b01Warp.nii.gz -t ants_t12b00GenericAffine.mat --default-value 2147483647

done

#correct warp
warpcorrect mrtrix_warp_t12b0[].nii mrtrix_warp_corrected_t12b0.nii -force

#warp image
mrtransform T1_brain.nii -warp mrtrix_warp_corrected_t12b0.nii ${subj}_warped_T12b0_brain.nii.gz -force

#unzip co-registered T1
gunzip ${subj}_warped_T12b0_brain.nii.gz

#register skull-stripped MNI to co-registered b0
antsRegistration --verbose 1 --dimensionality 3 --float 0 --output [ants_MNI2T1,antsWarped_MNI2T1.nii.gz,antsInverseWarped_MNI2T1.nii.gz] --interpolation Linear --use-histogram-matching 1 --winsorize-image-intensities [0.005,0.995] --transform Rigid[0.1] --metric CC[${subj}_warped_T12b0_brain.nii,mni_t1_brain.nii,1,4,Regular,0.1] --convergence [1000x500x250x100,1e-6,10] --shrink-factors 8x4x2x1 --smoothing-sigmas 3x2x1x0vox --transform Affine[0.1] --metric CC[${subj}_warped_T12b0_brain.nii,mni_t1_brain.nii,1,4,Regular,0.2] --convergence [1000x500x250x100,1e-6,10] --shrink-factors 8x4x2x1 --smoothing-sigmas 3x2x1x0vox --transform SyN[0.1,3,0] --metric CC[${subj}_warped_T12b0_brain.nii,mni_t1_brain.nii,1,4] --convergence [100x70x50x20,1e-6,10] --shrink-factors 4x2x2x1 --smoothing-sigmas 2x2x1x0vox -x [reference_mask.nii.gz,input_mask.nii.gz]

#generate an identity (deformation field) warp
warpinit mni_t1_brain.nii identity_warp_MNI2T1[].nii

#transform  identity warp
for i in {0..2}; do
antsApplyTransforms -d 3 -e 0 -i identity_warp_MNI2T1${i}.nii -o mrtrix_warp_MNI2T1${i}.nii -r ${subj}_b0_brain.nii -t ants_MNI2T11Warp.nii.gz -t ants_MNI2T10GenericAffine.mat --default-value 2147483647
done

#correct warp
warpcorrect mrtrix_warp_MNI2T1[].nii mrtrix_warp_corrected_MNI2T1.nii -force

#warp image
mrtransform mni_t1_brain.nii -warp mrtrix_warp_corrected_MNI2T1.nii ${subj}_warped_MNI2T1_brain.nii.gz -force

#apply warp to ROIs
for roi in $(cat ${ROI_LIST}) ; do
mrtransform ${roi}_ATLAS_2022a.nii -warp mrtrix_warp_corrected_MNI2T1.nii -interp nearest ${subj}_${roi}.nii -force

#upsample resulting ROIs back to 0.5x0.5x0.5 (applying warp will change to voxel grid of DWI image)
mrgrid ${subj}_${roi}.nii regrid -voxel 0.5 ${subj}_${roi}_highRes.nii -force
done

#upsample average b0 to 0.5x0.5x0.5 resolution to match ROIs
mrgrid ${subj}_warped_T12b0_brain.nii regrid -voxel 0.5 ${subj}_warped_T12b0_brain_highRes.nii

#check if output files that will store measures have headers (you can change to whatever you calculate)
for file in $OUTPUT_FILE_VTA_VOLUME $OUTPUT_FILE_PAG_VOLUME $OUTPUT_FILE_NTS_VOLUME $OUTPUT_FILE_LC_VOLUME $OUTPUT_FILE_DRN_VOLUME; do
    if [ ! -s "$file" ]; then
        echo "Subject_ID voxels volume(mm3)" > "$file"
    fi
done

#cycle through ROIs to calculate volume and append to main output files
for roi in $(cat ${ROI_LIST}); do
        output=$(fslstats ${subj}_warped_T12b0_brain_highRes.nii -k ${subj}_${roi}_highRes.nii -V)

        # Determine the correct output file for the current ROI
       if [ "$roi" == "VTA" ]; then
            OUTPUT_FILE=$OUTPUT_FILE_VTA_VOLUME
        elif [ "$roi" == "PAG" ]; then
            OUTPUT_FILE=$OUTPUT_FILE_PAG_VOLUME
        elif [ "$roi" == "NTS" ]; then
            OUTPUT_FILE=$OUTPUT_FILE_NTS_VOLUME
        elif [ "$roi" == "LC" ]; then
            OUTPUT_FILE=$OUTPUT_FILE_LC_VOLUME
        elif [ "$roi" == "DRN" ]; then
            OUTPUT_FILE=$OUTPUT_FILE_DRN_VOLUME
        fi

        # Check if the command produced any output
        if [ -z "$output" ]; then
            echo "fslstats didn't produce any output for ID $subj" >> $OUTPUT_FILE
        else
            # Append both ${subj} and the captured output to the OUTPUT_FILE
            echo "${subj} $output" >> $OUTPUT_FILE
        fi
    done

#check if output files that will store measures have headers (you can change to whatever you calculate)
for file in $OUTPUT_FILE_VTA_ICVF $OUTPUT_FILE_PAG_ICVF $OUTPUT_FILE_NTS_ICVF $OUTPUT_FILE_LC_ICVF $OUTPUT_FILE_DRN_ICVF; do
    if [ ! -s "$file" ]; then
        echo "Subject_ID ICVF" > "$file"
       fi
done

#upsample  to 0.5x0.5x0.5 resolution to match ROIs
mrgrid NODDI_ICVF.nii.gz regrid -voxel 0.5 NODDI_ICVF_highRes.nii.gz

#cycle through ROIs to calculate ICVF and append to main output files
for roi in $(cat ${ROI_LIST}); do
        output=$(mrstats NODDI_ICVF_highRes.nii.gz -mask ${subj}_${roi}_highRes.nii -output mean)

        # Determine the correct output file for the current ROI
       if [ "$roi" == "VTA" ]; then
            OUTPUT_FILE=$OUTPUT_FILE_VTA_ICVF
        elif [ "$roi" == "PAG" ]; then
            OUTPUT_FILE=$OUTPUT_FILE_PAG_ICVF
        elif [ "$roi" == "NTS" ]; then
            OUTPUT_FILE=$OUTPUT_FILE_NTS_ICVF
        elif [ "$roi" == "LC" ]; then
            OUTPUT_FILE=$OUTPUT_FILE_LC_ICVF
        elif [ "$roi" == "DRN" ]; then
            OUTPUT_FILE=$OUTPUT_FILE_DRN_ICVF
        fi

        # Check if the command produced any output
        if [ -z "$output" ]; then
            echo "mrstats didn't produce any output for ID $subj" >> $OUTPUT_FILE
        else
            # Append both ${subj} and the captured output to the OUTPUT_FILE
            echo "${subj} $output" >> $OUTPUT_FILE
        fi

done
  
#check if output files that will store measures have headers (you can change to whatever you calculate)
for file in $OUTPUT_FILE_VTA_ICVF $OUTPUT_FILE_PAG_ICVF $OUTPUT_FILE_NTS_ICVF $OUTPUT_FILE_LC_ICVF $OUTPUT_FILE_DRN_ICVF; do
    if [ ! -s "$file" ]; then
        echo "Subject_ID ICVF" > "$file"
       fi
done

#upsample  to 0.5x0.5x0.5 resolution to match ROIs
mrgrid NODDI_ISOVF.nii.gz regrid -voxel 0.5 NODDI_ISOVF_highRes.nii.gz

#cycle through ROIs to calculate ISOVF and append to main output files
for roi in $(cat ${ROI_LIST}); do
        output=$(mrstats NODDI_ISOVF_highRes.nii.gz -mask ${subj}_${roi}_highRes.nii -output mean)

        # Determine the correct output file for the current ROI
       if [ "$roi" == "VTA" ]; then
            OUTPUT_FILE=$OUTPUT_FILE_VTA_ISOVF
        elif [ "$roi" == "PAG" ]; then
            OUTPUT_FILE=$OUTPUT_FILE_PAG_ISOVF
        elif [ "$roi" == "NTS" ]; then
            OUTPUT_FILE=$OUTPUT_FILE_NTS_ISOVF
        elif [ "$roi" == "LC" ]; then
            OUTPUT_FILE=$OUTPUT_FILE_LC_ISOVF
        elif [ "$roi" == "DRN" ]; then
            OUTPUT_FILE=$OUTPUT_FILE_DRN_ISOVF
        fi

        # Check if the command produced any output
        if [ -z "$output" ]; then
            echo "mrstats didn't produce any output for ID $subj" >> $OUTPUT_FILE
        else
            # Append both ${subj} and the captured output to the OUTPUT_FILE
            echo "${subj} $output" >> $OUTPUT_FILE
        fi

done

#upsample  to 0.5x0.5x0.5 resolution to match ROIs
mrgrid NODDI_OD.nii.gz regrid -voxel 0.5 NODDI_OD_highRes.nii.gz

#cycle through ROIs to calculate OD and append to main output files
for roi in $(cat ${ROI_LIST}); do
        output=$(mrstats NODDI_OD_highRes.nii.gz -mask ${subj}_${roi}_highRes.nii -output mean)

        # Determine the correct output file for the current ROI
       if [ "$roi" == "VTA" ]; then
            OUTPUT_FILE=$OUTPUT_FILE_VTA_OD
        elif [ "$roi" == "PAG" ]; then
            OUTPUT_FILE=$OUTPUT_FILE_PAG_OD
        elif [ "$roi" == "NTS" ]; then
            OUTPUT_FILE=$OUTPUT_FILE_NTS_OD
        elif [ "$roi" == "LC" ]; then
            OUTPUT_FILE=$OUTPUT_FILE_LC_OD
        elif [ "$roi" == "DRN" ]; then
            OUTPUT_FILE=$OUTPUT_FILE_DRN_OD
        fi

        # Check if the command produced any output
        if [ -z "$output" ]; then
            echo "mrstats didn't produce any output for ID $subj" >> $OUTPUT_FILE
        else
            # Append both ${subj} and the captured output to the OUTPUT_FILE
            echo "${subj} $output" >> $OUTPUT_FILE
        fi

done

done
