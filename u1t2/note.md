# Using basic awk, grep and sed for manipulate real data

We all know about the power of the command line utilities but rarely this toolset is put to work. In this short note we are going to manipulate a csv file to extract some informations about it.

In order for the reader to fully understand the content of this tutorial, minimal knowledge of the command line is required. The file's name with all the data we will use is `all_month.csv`. You can put the file in wherever directory you want.

The data we will analyze is a comma separated values (CSV) simple text file and was taken from the United States Geological Survey (USGS), and it represents the seismic activities captured by sensors all over the country and other territories in the last 30 days which this note was written (march to april, 2022). You can download the dataset with this time period size or shorter ones [here](https://earthquake.usgs.gov/earthquakes/feed/v1.0/csv.php).

The first contact looks like this
![so many entries!](https://earthquake.usgs.gov/earthquakes/feed/v1.0/images/screenshot_csv.jpg)

Let's see how many entries this file has. We can do this using the `wc` command. We pass a additional option `-l` indicanting the number of lines.
```
wc -l all_month.csv

9271 all_month.csv
```
The file contains 9271 lines.
Now, let's take a look at the fields, using the `head -N` command. It prints out the first `N` lines. By default, it's 10.
```
head -1 all_month.csv
time,latitude,longitude,depth,mag,magType,nst,gap,dmin,rms,net,id,updated,place,type,horizontalError,depthError,magError,magNst,status,locationSource,magSource
```
For this tutorial, we are going to use just four of them: `time`, `depth`, `mag` and `place`. The output will be of the form: 2022-04-02 12:23:45, 10.1, 1.1, "4km SE of Honolulu - Hawaii".
So, how to split them? For this, we have the `cut`. the syntax is `cut -d<delim> -f<fields> <file>`, where the `-d` tells the delimiter, and `-f` inform the fields in numbers. First, lets cut the first three columns we care about.
```
cut -d, -f1,4,5 all_month.csv
```
Here, the delimiter is the comma, and the fields are the order that they appear. For example, if we wanted all fields from 2 to 5 we could use `-f2-5` (In the main example, `-f1,4-5` would return the same result).

Ok, everythins is looking good, let's add the `place` field. Adding it to the command: `cut -d, -f1,4,5,14 all_month.csv`:
```
cut -d, -f1,4,5,14 all_month.csv
…
2022-03-19T15:17:42.550Z,1.74,1.2,"8km NW of The Geysers
2022-03-19T15:13:52.070Z,3.59,0.6,"24 km SSW of Kanosh
2022-03-19T15:12:31.400Z,1.86,0.36,"7km WNW of Cobb
2022-03-19T15:10:07.880Z,26.4,0.48,"29 km N of Ivanof Bay
```
Well... It is a little different than expected, for instance, the final part of the `place` field was left out. But why? As you can see, we told the `cut` command to split every "cell" of our data file when it encounters a comma. This is why the `place` was ripped. It has a comma inside the text.

A solution for this is 
1. Extract the text of the `place` field and put it in a temporary file;
2. Extract the other fields and also put them in a temporary file;
3. Join the two files line by line.

It is worth to know that we can redirect the output of a command mostly in three ways:
- The output to a file, using the `>` operator;
- The error output to a file, using the `2>` operator;
- The output to the input of another command, using the `|` (pipe) operator.

Back to our case, how can we extract only the part of the line that contains the double quotes? The answer is `grep`. The `grep` command searches for a pattern of characters in the given object. It uses the power of regular expressions ([regex](https://en.wikipedia.org/wiki/Regular_expression)). We won't explain them in this article.

The command to find all the `place` entries is
```
grep -o '"[^"]\+"' all_month.csv
…
"8km NW of The Geysers, CA"
"24 km SSW of Kanosh, Utah"
"7km WNW of Cobb, CA"
"29 km N of Ivanof Bay, Alaska"
```
We can remove the commas with the `sed` command. It also works with regex, but in this case it will be more simple.
```
sed "s/,/ -/g"
```
Where `s/` means substitute, the `,` is the sequence we want to be substituted and ` -` is the sequence to replace. The `/g` tells to apply to all sequences in the whole line.

We can join these two commands with the pipe operator, which will redirect the output of the `grep` command to `sed`
```
grep -o '"[^"]\+"' all_month.csv | sed "s/,/ -/g"
…
"8km NW of The Geysers - CA"
"24 km SSW of Kanosh - Utah"
"7km WNW of Cobb - CA"
"29 km N of Ivanof Bay - Alaska"
```
We can now redirect this text to a temporary file (I will call `places_without_comma`
```
grep -o '"[^"]\+"' | sed "s/,/ -/g" > places_without_comma
```
Now, if you `ls` into your directory you will see a new file that contains the output above.

For the second step it will be similar, but with `cut`
```
 tail +2 all_month.csv | cut -d, -f1,4,5 > other_fields
```
The `tail` command is the opposite of head, it print the last `N` lines. The `+2` option will print out all the lines starting from the second. This will get rid of the header.

To join these two files, we will use a command called `paste`.
```
paste -d, other_fields places_without_comma > all_month_formatted.csv
```
As you can suspect, the `-d,` specifies the delimiter.

The `all_month_formatted.csv` file looks like this
```
2022-03-19T15:17:42.550Z,1.74,1.2,"8km NW of The Geysers - CA"
2022-03-19T15:13:52.070Z,3.59,0.6,"24 km SSW of Kanosh - Utah"
2022-03-19T15:12:31.400Z,1.86,0.36,"7km WNW of Cobb - CA"
2022-03-19T15:10:07.880Z,26.4,0.48,"29 km N of Ivanof Bay - Alaska"
```
### Extracting information with awk

What if we want the greater values involving the depth and magnitude of the earthquakes? We can do this using `awk`. Awk is by itself a fully capable programming language, optimized to dealing with text. A basic example is `awk -F, '{print $1}' all_month_formatted.csv` where it will print the first column of our file, acting like `cut -d, -f1`. By default it's delimiter is space, the same is valid for many of the other tools used here.

Jumping ahead, a script in awk for filter the greatest and smallest values of `depth` and `mag` can be:

`depth_mag_script.awk`
```
#!/usr/bin/env -S awk -f

BEGIN {FS="," ; maxDepth=0 ; maxMag=0}
{
    if (NR==1) {   # When it reads the first entry
        minDepth=$2;
        minMag=$3;
    }

    if ($2 > maxDepth)
        maxDepth = $2;
    else if ($2 < minDepth)
        minDepth = $2;

    if ($3 > maxMag)
        maxMag = $3;
    else if($3 < minMag)
        minMag = $3;
}
END {
    print "The deepest earthquake was " maxDepth " and the shallowest was " minDepth;
    print "The biggest earthquake was " maxMag " and the lowest was " minMag 
}

```
Where `FS` is the "file separator", `NR` is "number of records" and the $2 and $3 are the field's number. The `BEGIN` and `END` are self-explanatory.

```
./depth_mag_script.awk all_month_formatted.csv

The deepest earthquake was 623.78 and the shallowest was -3.5699999332428
The biggest earthquake was 7 and the lowest was -1.49
```
The negative magnitude is due to the logarithmic properties of the measurement scale.

Finally, we can format the date to `yyyy-mm-dd hh:MM:ss` and add spaces after the commas with `sed`. This time, passing the `-i` option to operate directly in the file.
```
sed -i "s/T/ / ; s/\.[0-9]*\S// ; s/,/, /g" all_month_formatted.csv
…
2022-03-19 15:17:42, 1.74, 1.2, "8km NW of The Geysers - CA"
2022-03-19 15:13:52, 3.59, 0.6, "24 km SSW of Kanosh - Utah"
2022-03-19 15:12:31, 1.86, 0.36, "7km WNW of Cobb - CA"
2022-03-19 15:10:07, 26.4, 0.48, "29 km N of Ivanof Bay - Alaska"
```

### Next Steps

The [pandas](https://pandas.pydata.org/) library is well known in the python and data science world, and for a reason. With it you could do all of this work easily. This is a example of a python script that does the same thing.

```
#!/usr/bin/env python3

import pandas as pd

df = pd.read_csv('all_month.csv', usecols=[0, 3, 4, 13, 14])
print(df.head(10))

max_depth = df['depth'].nlargest(1)
print(max_depth)

print('-'*10)

min_depth = df['depth'].nsmallest(1)
print(min_depth)

print('='*20)

max_mag = df['mag'].nlargest(1)
print(max_mag)

print('-'*10)

min_mag = df['mag'].nsmallest(1)
print(min_mag)
```
With this and much more, it worth giving the Pandas lib a try, if you haven't or didn't know it.


### Finally...
As my first post here, it certainly contains errors and could be improved. Feedback is always welcome!
