function v = isvalid(dataset)
% isvalid(dataset)
%
% Checks if supplied struct is a valid single-molecule 
% dataset instance

v = false;
if ~isstruct(dataset)
    return
end
if ~all(isfield(dataset, {'type', 'id', 'attr', 'columns', 'data'}))
    return
end
if ~all(isfield(dataset.data, {'id', 'attr', 'index', 'values'}))
    return
end
v = true;