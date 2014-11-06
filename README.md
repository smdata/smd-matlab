Single-molecule Dataset (SMD) Format
==

The single-molecule dataset (SMD) format has been jointly developed in the groups of Dan Herschlag ([Stanford](http://cmgm.stanford.edu/herschlag/)) and Ruben Gonzalez ([Columbia](http://www.columbia.edu/cu/chemistry/groups/gonzalez/index.html)) to facilitate publication and exchange of data and analysis results obtained in single-molecule studies.
This repository contains Matlab utility functions for creating, validating, saving and loading SMD structures in [Matlab](http://www.mathworks.com/products/matlab/). 

Format Description
--

The representation of a SMD structure in Matlab is as follows

> -   **dataset** : `struct`  
    -   **.id** : `string`  
        Unique identifier for collection of traces (e.g. a hash)
    -   **.desc** : `string`  
        Human-readable decriptor for dataset
    -   **.types** : `struct`  
        - **.index** : `"bool" | "float" | "double" | "int" | "long" | "string"`
          Data type for index
        - **.values** : `struct`
          Data types for column values. Each field **.column_name** contains a format string as in **.index**
    -   **.attr** : `struct`  
        Dataset level features (e.g. descriptors of experimental 
        conditions)
    -   **.data** : `1 x N struct`  
        -   **.id** : `string`  
            Unique identifier for trace (e.g. a hash)
        -   **.attr** : `struct`  
            Any trace-specific features that are not series
        -   **.index** : `1 x T vector`  
            Row index for trace data (e.g. acquisition times)
        -   **.values** : `struct`  
            Column values. Each field **.column_name** holds a `1 x T vector`

-  **desc**. This field serves to provide a simple descriptor of the data set contained herein. 
-   **id**. This field serves as a unique identifier for the particular set of traces that are grouped in this data structure. By default, a MD5 algorithm is used to generate a 32 digit hexadecimal number that is practically unique. This helps to ensure that when datasets generated at different times are combined, it remains easy to track the source of each dataset.
-   **attr**. The attributes field stores information related to a particular group of traces. This could be information such as the day the experiment was completed, the exact experimental conditions, or any other information that relates to the data set as a whole.
-   **types**. Holds type identifiers for the index and values fields.  Each field of data being stored in the values field should be specified here.  These identifiers are ‘bool’, ‘float’, ‘double’, ‘int’, ‘long’ and ‘string’.
-   **data**. Holds a list of entries for each trace, which themselves contain a set of fields:
    -   **id**. Holds a trace-specific identifier. By default a MD5 hash is of the values structure is used. 
    -   **index**. This field contains a list of row labels for the values matrix, which typically hold the measurement times. This field should have the same length as the data in the values field. 
    -   **values**. This field contains the actual single-molecule data. Most simply, each data type being used is stored in a field with a descriptive name (e.g., channel1). While this is primarily intended to store raw single-molecule data, it could equally well be used to store window-averaged data, thresholded data, fits of the data or an arbitrary number of other series data.
    -   **attr**. This attributes field has much the same role as the top-level attributes field, but is specific to this particular trace. Within this data field a user can store any additional information they are interested in storing. This could be anything from a kinetic or thermodynamic parameter algorithmically determined for a particular trace to an observation of that particular trace that an experimentalist wants to note for future reference.


Installation
--

1.  Download this repository from  
    https://github.com/smdata/smd-matlab/archive/master.zip  

2.  Unzip `master.zip` to some location (e.g. `c:\path\`)

3.  Add the `smdata` directory to the Matlab path by typing

    ```
    addpath(genpath('c:\path\smd-matlab\'))
    ```

    where `c:\path\` is the directory where `master.zip` was unpacked.

Functions
--

**smd.create(data, types, varargin)**: Creates a SMD structure from supplied data.

**smd.write_json(filename, dataset)**: Saves a SMD structure as JSON (`.json`)or compressed JSON (`.json.gz`).

**smd.read_json(filename)**: Loads a SMD structure from JSON (`.json`)or compressed JSON (`.json.gz`).

**smd.isvalid(dataset)**: Checks if supplied struct is a valid SMD instance.

**smd.filter(dataset)**: Returns a filtered dataset by matching `id` and `attr` values, or by applying a custom function with boolean output to each trace.

**smd.merge(data1, data2, ...)**: Returns a merged dataset containing all traces in multiple datasets.

Example Usage
--

Generate some fake data: Mixture of 3 Gaussian distributions

```matlab
state_mean = [0.1, 0.5, 0.7];
state_noise = [0.05, 0.10, 0.05];
num_traces = 10;
max_length = 100;
for n = 1:num_traces
    T = ceil(max_length * rand());
    states = ceil(length(state_mean) * rand(T,1));
    observations = state_mean(states)' + state_noise(states)' .* randn(T,1);
    data{n} = [states, observations];
end
```

Create a SMD structure
```matlab
% initialize smd structure
dataset = smd.create(data, {'state', 'int', 'observation', 'float'})
% add global attributes 
dataset.attr.description = 'example data: mixture of 3 gaussians with equal occupancy';
dataset.attr.state_mean = state_mean;
dataset.attr.state_noise = state_noise;
dataset.attr.max_length = max_length;
```

Save data to disk
```matlab
% save as Matlab data
save('example.mat', '-struct', 'dataset');
% save as plain text JSON (uncompressed)
smd.write_json('example.json', dataset);
% save as plain text JSON (with gzip compression)
smd.write_json('example.json.gz', dataset);
```

Load data from disk
```matlab
% read matlab data
example = load('example.mat');
% read plain text json (uncompressed)
example = smd.read_json('example.json', dataset);
% read plain text json (with gzip compression)
example = smd.read_json('example.json.gz', dataset);
```

Filter data
```matlab
% filter out traces with <= 50 data points
filtered = smd.filter(example, 'func', @(d) size(d.values,1) > 50);
```