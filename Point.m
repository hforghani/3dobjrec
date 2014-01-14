classdef Point
    %POINT Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        pos;
        color;
        measure_num;
        measurements;
        
        descriptor;
    end
    
    methods
        function self = Point(pos, color, measure_num, measurements)
            self.pos = pos;
            self.color = color;
            self.measure_num = measure_num;
            self.measurements = measurements;
        end
        
        function self = calc_descriptors(self, img_fold_name, model)
%             desc_arr = [];
            for i = 1:self.measure_num
                meas = self.measurements{i};
                meas = meas.calc_descriptors(img_fold_name, model);
%                 desc_arr = [desc_arr, meas.descriptors];
            end
%             self.descriptor = desc_arr;
        end
    end
    
end
