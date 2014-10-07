function v = isvalid(dataset)
% isvalid(dataset)
%
% Checks if supplied struct is a valid single-molecule 
% dataset instance

v = false;
if ~isstruct(dataset)
    return
end
% check that all required top-level fields exist
if ~all(isfield(dataset, {'desc', 'id', 'attr', 'types', 'data'}))
    return
end
% check column specifiers
columns = fieldnames(dataset.types);
for c = 1:length(columns)
	if ~any(strcmpi(dataset.types.(columns{c}), {'bool', 'float', 'double', 'int', 'long', 'string'}))
	    return
	end
end
% check that all required data-level fields exist
if ~all(isfield(dataset.data, {'id', 'attr', 'index', 'values'}))
    return
end
v = true;