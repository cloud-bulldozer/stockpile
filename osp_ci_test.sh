#/bin/bash

JENKINSDIR=${jenkins_dir}
BASEDIR="/home/stockpile/ospci"
VENVDIR="$BASEDIR/venv"
UNDERCLOUD_IP=${undercloud_ip}
COMPUTE_IP=${compute_ip}
CONTROLLER_IP=${controller_ip}

sed -i -e  's/undercloud_ip/'"$UNDERCLOUD_IP"'/g' -e  's/compute_ip/'"$COMPUTE_IP"'/g' -e  's/controller_ip/'"$CONTROLLER_IP"'/g' $JENKINSDIR/ci/hosts
cd $BASEDIR
source $VENVDIR/bin/activate
cd
source ~/stackrc
cd $JENKINSDIR
# Prep the results_osp.markdown file
echo "Results for "$JOB_NAME > results_osp.markdown
echo "" >> results_osp.markdown
echo 'Tag | SubTag | ok | changed | unreachable | failed | Returned info' >> results_osp.markdown
echo '-----|------- |---|---------|-------------|--------|--------' >> results_osp.markdown
# Setup hosts and vars for CI environment
cp ci/all.yml group_vars/all.yml
cp config/featureset001.yml $JENKINSDIR/
labels=("oc_*" "uc_*")
for label in ${labels[@]}
do
  tag_list=`grep 'tags: '"$label"'' featureset001.yml | grep -v '^ *#'| awk '{print $(NF-1)}'`
  echo $tag_list
  if [ $label = "oc_*" ]; then
    array=("controller.*" "compute.*")
  elif [ $label = "uc_*" ]; then 
    array=("undercloud.*")
  else
    pass
  fi
  for tag in $tag_list
  do
    figlet $tag
    for i in "${array[@]}"; do
      results=`ansible-playbook -i ci/hosts featureset001.yml  -v --tags=openstack_common,$tag,dump-facts | grep "$i ok=.*changed=.*unreachable=.*failed=.*"`
      echo $results
      # set resulting variables
      res=`echo $results | sed 's/=/ /g'`
      subtag=`echo $res | awk '{print $1}'`
      ok=`echo $res | awk '{print $4}'`
      changed=`echo $res | awk '{print $6}'`
      unreachable=`echo $res | awk '{print $8}'`
      failed=`echo $res | awk '{print $10}'`  
      check_json=`python ci/check_json.py -i /tmp/stockpile.json`
      echo "Results from: stockpile_osp_job"
      if [[ -z $check_json ]]; then
        echo "Returned no information"
        echo $tag"|"$subtag"|"$ok"|"$changed"|"$unreachable"|"$failed"|Returned NO information" >> results_osp.markdown
      else
        echo "Returned Valid json"
        echo $tag"|"$subtag"|"$ok"|"$changed"|"$unreachable"|"$failed"|Returned valid JSON information" >> results_osp.markdown
      fi
    echo""
    done
    echo $check_json
  done
done
