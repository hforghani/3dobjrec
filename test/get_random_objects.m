function names = get_random_objects(obj_names)

n = length(obj_names);
combs = nchoosek(1:n, randi(3));
names = obj_names(combs(randi(size(combs,1)), :));

end
