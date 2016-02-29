#!/bin/bash

timestamp=`date +'%Y%m%d_%H%M'`
day_of_the_week=`date +%u`
#day_of_the_week=$1
application_user='nexus'
application_server='10.156.0.27'
orig_backup='/opt/sonatype/nexus/sonatype-work/nexus/storage/sdk-artifacts/'
base_backup_dir='/tmp/test_nexus_backups'
#what_to_exclude_rsync="\.*"   ### for now just single folder or wildcard
what_to_exclude_grep=".nexus"
s3_folder="s3://mns-devops-backup/devops/cd/prod/nexus3/"

### --- setting init arguments
if [ ${day_of_the_week} == 1 ];
then
    current_backup="${day_of_the_week}-day"
    prev_backup='full-backup'
elif [ ${day_of_the_week} == 6 ];
then
    current_backup="full-backup"
    prev_backup='full-backup'
else
    current_backup="${day_of_the_week}-day"
    let prev_backup=${day_of_the_week}-1
    prev_backup="${prev_backup}-day"
fi

full_file_name="${current_backup}-${timestamp}.tar.gz"
diff_file_name="${current_backup}-${timestamp}.tar.gz"
restore_file_name="restore-file-${timestamp}.sh"

current_backup=${base_backup_dir}/${current_backup}
prev_backup=${base_backup_dir}/${prev_backup}
full_backup=${base_backup_dir}/full-backup

### --- creating required folders and cleaning them up

mkdir -p ${current_backup}
mkdir -p ${prev_backup}
mkdir -p ${base_backup_dir}/dist
rm -rf ${base_backup_dir}/dist/*


full_backup()
{
### --- copying required files

    echo -e "\n\n ---- creating FULL backup `date`"

   /usr/bin/rsync -ae "ssh -o StrictHostKeyChecking=no" --delete --no-owner --no-p --no-g --exclude=".*/" \
   ${application_user}@${application_server}:${orig_backup} ${prev_backup}

   cd ${base_backup_dir}/dist/
   tar -czvf ${full_file_name} ${current_backup}
   aws s3 cp ${diff_file_name} ${s3_folder}
}

diff_backup()
{
  echo -e "\n\n ---- creating Differential Backup `date`"
  [ -n "${current_backup}" ] && rm -rf ${current_backup}/*

### --- getting list of diff files
IFS=$'\n' diff_list=( $(rsync -rvune "ssh -o StrictHostKeyChecking=no" \
   --no-owner --no-p --no-g --no-d --exclude=".*/" \
   ${application_user}@${application_server}:${orig_backup} ${full_backup} \
 | grep -v "sending incremental file list" \
 | grep -E -v ".*\/$" \
 | grep -v "${what_to_exclude_grep}" \
 | sed 's/sent .*$//;s/total size.*$//;/^$/d' \
 | sed '1d' 2>/dev/null) )

modified=`printf "%s\n" ${diff_list[@]} | grep -v deleting`
deleted=`printf "%s\n" ${diff_list[@]} | grep deleting | sed 's/deleting //g'`

#checking if previous folderis empty
   f_check()
   {
   folder_check=`ls ${prev_backup}`
   if [ -z "${folder_check}" ]
   then
     if [ ${prev_backup} == "${base_backup_dir}/full-backup" ]
     then
     full_backup
     else
     new_folder=`echo ${prev_backup} | sed 's/.*\///;s/-day//'`
     let new_folder=new_folder-1
       if [ ${new_folder} == 0 ]
       then new_folder="full-backup"
       else new_folder="${new_folder}-day"
       fi
     prev_backup="${base_backup_dir}/${new_folder}"
     f_check
     fi
   fi
   }

f_check
from_previous_backup=`ls ${prev_backup}`


diff_modified=""
for diff in ${modified}
do
   temp=`echo ${from_previous_backup} | grep "${diff}"`
if [ -z "${temp}" ] ;
then
diff_modified="${diff_modified} ${diff}"

fi
done

echo ${diff_modified}
#exit 1

cd ${base_backup_dir}/dist/

cat <<  EOF > ${restore_file_name}

#!/bin/bash

if [ -n "${deleted}" ];
then rm -rf ${deleted}
else echo "Nothig to delete"
fi

if [ -n "${modified}" ];
then /bin/cp -vfr * ${data_to_backup}
else echo "Nothing to copy"
fi

EOF


diff_modified=`echo ${diff_modified} | sed 's/ /\n/g'`
#for i in ${diff_modified[*]}
#do
#echo $i
#done

#exit 1
diff_modified_folders=`echo ${diff_modified} | sed "s#^#${current_backup}/#g;s# # ${current_backup}/#g"`
#echo ${diff_modified_folders}

    for file in ${diff_modified[*]}
    do
      scp -r ${application_user}@${application_server}:${orig_backup}${file} ${current_backup}/
    done
    pwd
    echo "#####  ---  tar -czvf ${diff_file_name} ${restore_file_name} ${diff_modified_folders}"
    tar -czvf ${diff_file_name} ${restore_file_name} ${diff_modified_folders}
    echo "#####  ---  aws s3 cp ${diff_file_name} ${s3_folder}"
    aws s3 cp ${diff_file_name} ${s3_folder}
}


if [ ${day_of_the_week} == 6 ];
then
  full_backup
else
  diff_backup
fi

