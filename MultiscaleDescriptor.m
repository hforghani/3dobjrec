classdef MultiscaleDescriptor
    %MULTISCALEDESCRIPTOR Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        frames_array;
        descriptors_array;
    end
    
    methods
        function self = MultiscaleDescriptor(frames_array, descriptors_array)
            self.frames_array = frames_array;
            self.descriptors_array = descriptors_array;
        end
        
        function [f, d, min_dist] = get_best_match(self, desc)
            scales_size = size(self.frames_array, 1);
            min_dist = -1;
            f = []; d = [];
            for s = 1 : scales_size
                self_desc = self.descriptors_array{s};
                other_desc = desc.descriptors_array{s};
                for self_i = 1 : size(self_desc, 2)
                    for other_i = 1 : size(other_desc, 2)
                        dist = norm(self_desc(:,self_i) - other_desc(:,other_i));
                        if dist < min_dist
                            min_dist = dist;
                            d = self_desc(:,self_i);
                            f = self.frames_array{s}(:,self_i);
                        end
                    end
                end
            end
        end
    end
    
end

