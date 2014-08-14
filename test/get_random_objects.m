function names = get_random_objects(n)

switch n
    case 10
        fname = 'data/model_desc/all10';
    case 20
        fname = 'data/model_desc/all20';
    case 30
        fname = 'data/model_desc/all30';
    case 40
        fname = 'data/model_desc/all40';
    case 50
        fname = 'data/model_desc/all50';
    otherwise
        error('invalid n');
end

load(fname, 'obj_names');
combs = nchoosek(1:n, randi(3));
names = obj_names(combs(randi(size(combs,1)), :));

end
