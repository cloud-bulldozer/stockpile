#/bin/bash

#copy the stockpile in the undercloud
BASEDIR="/home/stockpile/ospci"
VENVDIR="$BASEDIR/venv"

cd $BASEDIR
source $VENVDIR/bin/activate
cd
scp -r ~/stockpile stack@undercloud-0:~/
ssh -T -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -i ~/.ssh/id_rsa stack@undercloud-0 <<'EOSSH'
  source stackrc
  cd ~/stockpile
  pushd ~/stockpile
  # Prep the results.markdown file
  echo "Results for "$JOB_NAME > results.markdown
  echo "" >> results.markdown
  echo 'Tag | SubTag | ok | changed | unreachable | failed | Returned info' >> results.markdown
  echo '-----|------- |---|---------|-------------|--------|--------' >> results.markdown
  # Setup hosts and vars for CI environment
  cp ci/all.yml group_vars/all.yml
  # Get the list of tags from stockpile.yml (minus lines beginning with #)
  tag_list=`grep tags config/featureset001.yml | grep -v '^ *#'| awk '{print $(NF-1)}'`
  echo $tag_list
  array=("compute.*" "controller.*" "undercloud.*")
  for tag in $tag_list
  do
     echo $tag
     for i in "${array[@]}"; do
       results=`ansible-playbook -i ci/hosts config/featureset001.yml --tags=$tag | grep "$i ok=.*changed=.*unreachable=.*failed=.*"`
       echo $results
       # set resulting variables
       res=`echo $results | sed 's/=/ /g'`
       subtag=`echo $res | awk '{print $1}'`
       ok=`echo $res | awk '{print $4}'`
       changed=`echo $res | awk '{print $6}'`
       unreachable=`echo $res | awk '{print $8}'`
       failed=`echo $res | awk '{print $10}'`
       check_json=`python ci/check_json.py -i /tmp/stockpile.json`
       echo "Results from: "$tag
       if [[ -z $check_json ]]
       then
         echo "Returned no information"
         echo $tag"|"$subtag"|"$ok"|"$changed"|"$unreachable"|"$failed"|Returned NO information" >> results.markdown
       else
         echo $check_json
         echo $tag"|"$subtag"|"$ok"|"$changed"|"$unreachable"|"$failed"|Returned valid JSON information" >> results.markdown
       fi
    echo ""
    done
   done
  popd
EOSSH

