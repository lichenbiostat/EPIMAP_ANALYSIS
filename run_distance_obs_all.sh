#!/bin/bash
# =================================================
# Run all GWcorr comparisons for impobs + all files
# Speed up by eval only chr1.
# qsub -cwd -P compbio_lab -t 1-2051 -l h_vmem=12G -l h_rt=24:00:00 -N io_compare_all -j y -b y -V -r y -o $DBDIR/out/ChromImpute "$BINDIR/run_distance_obs_all.sh"
# =================================================
start=`date +%s`
hostname -f
TASK=${SGE_TASK_ID} # 1-2051
TMP_DIR=${TMP}/sampdist_${TASK}_${RANDOM}
mkdir -p ${TMP_DIR}
source /broad/compbio/cboix/EPIMAP_ANALYSIS/bin/config_ChromImpute.sh $NUMSTATES

# Arguments/locations:
INFOFILE=${DBDIR}/impobs_comb_tocompare.tsv
OUTDIR=${CIDIR}/io_compare_distance
mkdir -p $OUTDIR

SAMPLE=$( sed "${TASK}q;d" ${INFOFILE} | awk -v FS="\t" '{print $1}' )
MARK=$( sed "${TASK}q;d" ${INFOFILE} | awk -v FS="\t" '{print $2}' )
stag=${SAMPLE}_obs_${MARK}
echo "[STATUS] Running all comparisons against sample: $SAMPLE $MARK"

# ---------------------------------
# Make sample specific samplesheet:
# ---------------------------------
TMP_TAB=${TMP_DIR}/against_table.tsv
TMP_CHR=${TMP_DIR}/tmp_chromsizes
grep -e "${SAMPLE}_obs" $ALL_UQ_TAB | grep "$MARK" | awk -vOFS="\t" '{print $1"_"$2, "all", $3}'  > ${TMP_TAB}
grep "_imp" ${ALL_UQ_TAB} | awk -vOFS="\t" '{split($1,a,"_"); print a[1]"_"$2, "all", $3}' >> ${TMP_TAB}
head -n 1 ${CHROMSIZES_noY} > $TMP_CHR

echo "[STATUS] Compute global distance between datasets with ComputeGlobalDist"
# Run distance (only chr1)
if [[ ! -s ${OUTDIR}/${stag}_all.txt ]]; then
    echo "[STATUS] Computing for $stag against all."
    java -mx8000M -Djava.io.tmpdir=${TMP_DIR} -jar ${CHROMIMPUTE} ComputeGlobalDist -s ${stag} "all" ${IMPUTED_DIR} ${TMP_TAB} ${TMP_CHR} ${OUTDIR}
else
    echo "[STATUS] Dist for $stag v. all exists at ${OUTDIR}/${stag}_all.txt"
fi

rm -rf ${TMP_DIR}

end=`date +%s`
runtime=$((end-start))
echo "Finished obs compared to all imputed (# $TASK) sucessfully in $runtime seconds."
