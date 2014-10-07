function dataset = create(data, types, varargin)
% dataset = create(data, types, varargin)
%
% Creates a single-molecule dataset structure from supplied data.
%
% Inputs
% ------
%   data : N x 1 cell,  M x D numeric,  N x T x D numeric
%       Time series data. May be formatted in 3 ways
%       1. As a cell array, where each data{n} is a T{n} x D array
%       2. As a T x D 'stacked' array, e.g. of form [id, time, values]
%       3. As a N x T x D array 
%   types : cell
%       Format specifier for data of the form {'column','format', ...}. 
%       Each 'format' specifier may be one of {'bool','float','int','long','string'}. If the supplied data is in 
%       stacked form, the type specifier must contain entries 
%       {'id','format'}
%
% Variable Inputs
% ---------------
%   index : N x T  or N x 1 cell of T{n} x 1 float
%       May be used to separately specify time index values. Overrides 
%       entries supplied in data argument.
%   desc : string
%       Descriptor for data. Constructed from columns if left blank.
%   id : string
%       Unique id for dataset. Computed using hash if not specified.
%   attr : struct
%       May be used to provide additional annotation of data.
%   data_ids : N x 1 cell 
%       Unique ids for traces. Computed using hash if not specified.
%   data_attrs : N x 1 struct 
%       May be used to store additional information specific to each
%       individual time series.

% parse inputs
ip = inputParser();
ip.StructExpand = false;
ip.addRequired('data');
ip.addRequired('types', @iscell);
ip.addParamValue('index', {});
ip.addParamValue('desc', '', @isstr);
ip.addParamValue('id', '', @isstr);
ip.addParamValue('attr', struct(), @isstruct);
ip.addParamValue('data_ids', {}, @iscell);
ip.addParamValue('data_attrs', struct(), @isstruct);
ip.parse(data, types, varargin{:});
args = ip.Results;


% parse type arguments
col_labels = args.types(1:2:end);
col_formats = args.types(2:2:end);

% identify index and id columns (if provided)
[m, i] = ismember('index', lower(col_labels));
index_column = m * i;
[m, i] = ismember('id', lower(col_labels));
id_column = m * i;
value_columns = setdiff(1:length(col_labels), [index_column, id_column]);
D = length(value_columns);

% helper function for parsing data argument
function d = parse_data(data, ...
                        col_labels, col_formats, ...
                        dfs, tf, idf)
    % determine if data is stackedxw
    if idf
        % split by id
        id = data(:, idf);
        ids = unique(id);
        for n = 1:length(ids)
            d(n).id = num2str(ids(n));
            i = find(id == ids(n));
            if tf 
                d(n).index = data(i, tf)';
            else
                d(n).index = 1:length(i);
            end
            for c = dfs
                d(n).values.(columns{c}) = data(i, c)';
            end
        end
    else
        % assume single trace with blank id
        d.id = '';        
        if tf
            d.index = data(:, tf)';
        else
            d.index = 1:length(data);
        end
        for c = dfs
            d.values.(col_labels{c}) = data(:, c)';
        end
    end
end

% parse data argument
if iscell(args.data)
    data = cellfun(@(d) parse_data(d, ...
                                   col_labels, col_formats, ...
                                   value_columns, index_column, id_column), ... 
                   {args.data{:}});
elseif isnumeric(args.data)
    switch ndims(args.data)
        case 2
            data = parse_data(args.data, value_columns, index_column, id_column);
        case 3
            data = ...
                arrayfun(@(n) parse_data(squeeze(args.data(n,:,:)), ...
                                         value_columns, index_column, id_column), ...
                         1:size(args.data, 1));
        otherwise
            error('SMD:InvalidInput', ...
                  'The data argmument must have either have size [N T D] or [M D]');
    end
else
    error('SMD:InvalidInput', ...
          'The "data" argument must either be a cell or numeric array.');
end

% set indexes if specified
if not(isempty(args.index))
    if iscell(args.index)
        index = args.index;
    elseif isnumeric(args.index)
        index = num2cell(args.index, 2);
    else
        error('SMD:InputsNotAligned', ...
              'The "index" argument must either be a cell or numeric array.');
    end
    if length(args.index) ~= length(data)
        error('SMD:InvalidInput', ...
              'Number of specified index values (%d) does not match number of series parsed from data (%d)', ...
              length(index), length(data));
    end
    for n = 1:length(data)
        data(n).index = index{n}(:);
    end
end

% set id's if specified
if not(isempty(args.data_ids))
    if length(args.data_ids) ~= length(data)
        error('SMD:InputsNotAligned', ...
              'Number of specified data_ids (%d) does not match number of time series parsed from data (%d)', ...
              length(args.data_ids), length(data));
    end
    for n = 1:length(data)
        data(n).id = args.data_ids{n};
    end
end

% set attr's if specified
if length(args.data_attrs) > 1
    if length(args.data_attrs) ~= length(data)
        error('SMD:InputsNotAligned', ...
              'Number of specified data_attrs (%d) does not match number of series parsed from data (%d)', ...
              length(args.data_attrs), length(data));
    end
    for n = 1:length(data)
        data(n).attr = args.data_attrs(n);
    end
else 
    [data.attr] = deal(struct());
end

% replace any empty time series ids with hashes
for n = 1:length(data)
    if isempty(data(n).id)
        data(n).id = datahash.datahash(data(n));
    end
end

% calculate set id from hash if necessary
if isempty(args.id)
    id = datahash.datahash(data);
else
    id = args.id;
end

% desc contains column labels if unspecified

if isempty(args.desc)
    args.desc = strjoin(col_labels, '-');
end

% assign data structure
dataset = struct();
dataset.desc = args.desc;
dataset.id = id;
dataset.attr = args.attr;
dataset.types = struct(args.types{:});
dataset.data = data;
end