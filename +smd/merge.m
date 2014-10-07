function dataset = merge(varargin)
    % dataset = filter(varargin)
    %
    % Merges supplied single-molecule datasets into a single 
    % structure. Any dataset-level attributes which are not 
    % identical for all datasets are made attributes of individual 
    % time series. Conversely, all series level attributes that are 
    % identical for the entire dataset, are made dataset level 
    % attributes.

    datasets = cellfun(@(d) d(:), varargin, 'UniformOutput', false);
    datasets = cat(1, datasets{:});


    for n = 2:length(datasets)
        % check that column names are the same
        if ~all(strcmp(fieldnames(datasets(1).types.values), fieldnames(datasets(n).types.values)))
            error('SMD:ColumnsMismatch', ...
                  'Column labels are not consistent for all arguments.')
        end    
        % check that column data types are the same
        if ~strcmp(datasets(1).types.index, datasets(n).types.index)
            error('SMD:TypeMismatch', ...
                  'Data types are not consistent for all arguments.')
        end    
        if ~all(strcmp(struct2cell(datasets(1).types.values), struct2cell(datasets(n).types.values)))
            error('SMD:TypeMismatch', ...
                  'Data types are not consistent for all arguments.')
        end    
    end

    % copy dataset level attrs to individual traces
    for d = 1:length(datasets)
        attrs = [datasets(d).data.attr];
        for f = fieldnames(datasets(d).attr)'
            [attrs.(char(f))] = deal(datasets(d).attr.(char(f)));
        end
        for n = 1:length(datasets(d).data)
            datasets(d).data(n).attr = attrs(n);
        end
    end

    % initialize merged dataset
    dataset = struct('id', {}, 'attr', {}, 'types', {}, 'data', {});
    dataset(1).types = datasets(1).types;
    dataset.data = struct('id', {}, 'attr', {}, 'index', {}, 'values', {});

    mmin = 0;
    for d = 1:length(datasets)
        for n = 1:length(datasets(d).data)
            m = mmin + n;
            [dataset.data(m).id] = datasets(d).data(n).id;        
            [dataset.data(m).index] = datasets(d).data(n).index;        
            [dataset.data(m).values] = datasets(d).data(n).values;
            for f = fieldnames(datasets(d).data(1).attr)'
                [dataset.data(m).attr.(char(f))] = ...
                    datasets(d).data(n).attr.(char(f));
            end
        end
        mmin = mmin + length(datasets(d).data);
    end

    % move all identical attributes back to dataset level
    attrs = [dataset.data.attr];
    if ~isempty(attrs)
        for f = fieldnames(attrs)'
            f = char(f);
            if all(arrayfun(@(a) isequal(a.(f), attrs(1).(f)), attrs))
                dataset.attr.(f) = attrs(1).(f);
                attrs = rmfield(attrs, f);
            end
        end
        for n = 1:length(dataset.data)
            dataset.data(n).attr = attrs(n);
        end
    end

    % calculate id from hash
    dataset.id = datahash.datahash(dataset.data);
end