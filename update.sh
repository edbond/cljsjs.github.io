#!/bin/bash
data=$(curl --connect-timeout 5 -s https://clojars.org/api/groups/cljsjs)

if [[ $? != "0" ]]; then
    echo "ERROR: Clojars is down"
    exit
fi

CACHE=~/.m2/repository/cljsjs
OUT=_includes/packages.html

echo "" > $OUT
echo "<ul>" >> $OUT


IFS=$'\n'
for e in $(echo $data | jq -c ".[]"); do
    group=$(echo $e | jq -r ".group_name")
    artifact=$(echo $e | jq -r ".jar_name")
    id="$group/$artifact"
    rversion=$(echo $e | jq -r ".latest_version")
    version=$(echo $e | jq ".latest_version")
    description=$(echo $e | jq -r ".description" | sed 's/&(?!amp;)/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g; s/"/\&quot;/g; s/'"'"'/\&#39;/g')
    homepage=$(echo $e | jq -r ".homepage")

    jarfile="$artifact/$rversion/$artifact-$rversion.jar"
    mkdir -p $(dirname $CACHE/$jarfile)
    if [[ ! -f $CACHE/$jarfile ]]; then
        curl -o $CACHE/$jarfile https://clojars.org/repo/cljsjs/$jarfile
    fi
    deps=$(unzip -p $CACHE/$jarfile deps.cljs)

    echo "  <li>" >> $OUT
    echo "    <a href=\"https://clojars.org/${id}\">${artifact}</a>" >> $OUT
    echo "    <a href=\"$homepage\" target=\"new\"><i class=\"fa fa-home\"></i></a>" >> $OUT
    echo "    <span class=\"clojars\">" >> $OUT
    echo "      <input type=\"text\" value='[${id} ${version}]'/>" >> $OUT
    echo "      <button data-clipboard-text='[${id} ${version}]'><i class=\"fa fa-copy\"></i></button>" >> $OUT
    echo "    </span>" >> $OUT
    echo "    <p class=\"description\">$description</p>" >> $OUT
    echo "    <pre class=\"deps\">$deps</pre>" >> $OUT
    echo "  </li>" >> $OUT
done

echo "</ul>" >> $OUT
