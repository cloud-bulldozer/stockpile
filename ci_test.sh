#/bin/bash

# Prep the results.markdown file
echo "Results for "$JOB_NAME > results.markdown
echo "" >> results.markdown
echo 'Tag | ok | changed | unreachable | failed | skipped | rescued | ignored | Returned info' >> results.markdown
echo '-----|---|---------|-------------|--------|---------|---------|------|--------' >> results.markdown

kube_config=$1

export KUBECONFIG=$kube_config

# Setup hosts and vars for CI environment
cp ci/all.yml group_vars/all.yml

# Get the list of tags from stockpile.yml (minus lines beginning with #)
tag_list=`grep tags stockpile.yml | grep -v '^ *#'| awk '{print $(NF-1)}'`

for tag in $tag_list
do
  figlet $tag
  results=`ansible-playbook -i ci/hosts stockpile.yml --tags=$tag,dump-facts | grep "ok=.*changed=.*unreachable=.*failed=.*skipped=.*rescued=.*ignored=.*"`

  echo $results
  
  # set resulting variables
  res=`echo $results | sed 's/=/ /g'`
  ok=`echo $res | awk '{print $4}'`
  changed=`echo $res | awk '{print $6}'`
  unreachable=`echo $res | awk '{print $8}'`
  failed=`echo $res | awk '{print $10}'`
  skipped=`echo $res | awk '{print $12}'`
  rescued=`echo $res | awk '{print $14}'`
  ignored=`echo $res | awk '{print $16}'`

  if [[ $tag == "backpack_kube" ]]
  then
    backpack=`ls /tmp/container/`
    check_json=`python3 ci/check_json.py -i /tmp/container/$backpack`
    rm -f /tmp/container/$backpack
  else
    check_json=`python3 ci/check_json.py -i /tmp/stockpile.json`
  fi

  echo "Results from: "$tag
  if [[ -z $check_json ]]
  then
    echo "Returned no information"
    echo $tag"|"$ok"|"$changed"|"$unreachable"|"$failed"|"$skipped"|"$rescued"|"$ignored"|Returned NO information" >> results.markdown
  else  
    echo $check_json
    echo $tag"|"$ok"|"$changed"|"$unreachable"|"$failed"|"$skipped"|"$rescued"|"$ignored"|Returned valid JSON information" >> results.markdown
  fi
  echo ""
done
