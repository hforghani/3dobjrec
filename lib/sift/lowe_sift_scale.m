function scale = lowe_sift_scale( im, poses, interactive, octaves, intervals )

% inspired from Thomas F. El-Maraghi's code
% May 2004

% assign default values to the input variables
if ~exist('octaves')
   octaves = 4;
end
if ~exist('intervals')
   intervals = 2;
end
if ~exist('object_mask')
   object_mask = ones(size(im));
end
if size(object_mask) ~= size(im)
   object_mask = ones(size(im));
end
if ~exist('contrast_threshold')
   contrast_threshold = 0.02;
end
% if ~exist('curvature_threshold')
%    curvature_threshold = 10.0;
% end
if ~exist('interactive')
   interactive = 1;
end

% Check that the image is normalized to [0,1]
if( (min(im(:)) < 0) | (max(im(:)) > 1) )
   fprintf( 2, 'Warning: image not normalized to [0,1].\n' );
end

pose_count = size(poses,2);

% Blur the image with a standard deviation of 0.5 to prevent aliasing
% and then upsample the image by a factor of 2 using linear interpolation.
% Lowe claims that this increases the number of stable keypoints by 
% a factor of 4.
if interactive >= 1
   fprintf( 2, 'Doubling image size for first octave...\n' );
end
tic;
antialias_sigma = 0.5;
if antialias_sigma == 0
   signal = im;
else
   g = gaussian_filter( antialias_sigma );
   if exist('corrsep') == 3
	   signal = corrsep( g, g, im );
   else
      signal = conv2( g, g, im, 'same' );
   end
end
signal = im;
[X Y] = meshgrid( 1:0.5:size(signal,2), 1:0.5:size(signal,1) );
signal = interp2( signal, X, Y, '*linear' );   
subsample = [0.5]; % subsampling rate for doubled image is 1/2


% The next step of the algorithm is to generate the gaussian and difference-of-
% gaussian (DOG) pyramids.  These pyramids will be stored as two cell arrays,
% gauss_pyr{orient,interval} and DOG_pyr{orient,interval}, respectively.  In order
% to detect keypoints on s intervals per octave, we must generate s+3 blurred
% images in the gaussian pyramid.  This is becuase s+3 blurred images generates
% s+2 DOG images, and two images are needed (one at the highest and one lowest scales 
% of the octave) for extrema detection.

% Generate the first image of the first octave of the gaussian pyramid
% by preblurring the doubled image with a gaussian with a standard deviation
% of 1.6.  This choice for sigma is a trade off between repeatability and
% efficiency.
if interactive >= 1
   fprintf( 2, 'Prebluring image...\n' );
end
preblur_sigma = sqrt(sqrt(2)^2 - (2*antialias_sigma)^2);
if preblur_sigma == 0
   gauss_pyr{1,1} = signal;
else
   g = gaussian_filter( preblur_sigma );
   if exist('corrsep') == 3
      gauss_pyr{1,1} = corrsep( g, g, signal );
   else
      gauss_pyr{1,1} = conv2( g, g, signal, 'same' );
   end
end
clear signal
pre_time = toc;
if interactive >= 1
   fprintf( 2, 'Preprocessing time %.2f seconds.\n', pre_time );
end

% The initial blurring for the first image of the first octave of the pyramid.
initial_sigma = sqrt( (2*antialias_sigma)^2 + preblur_sigma^2 );

% Keep track of the absolute sigma for the octave and scale
absolute_sigma = zeros(octaves,intervals+3);
absolute_sigma(1,1) = initial_sigma * subsample(1);

% Keep track of the filter sizes and standard deviations used to generate the pyramid
filter_size = zeros(octaves,intervals+3);
filter_sigma = zeros(octaves,intervals+3);

% Generate the remaining levels of the geometrically sampled gaussian and DOG pyramids
if interactive >= 1
   fprintf( 2, 'Expanding the Gaussian and DOG pyramids...\n' );
end
tic;
for octave = 1:octaves
   if interactive >= 1
      fprintf( 2, '\tProcessing octave %d: image size %d x %d subsample %.1f\n', octave, size(gauss_pyr{octave,1},2), size(gauss_pyr{octave,1},1), subsample(octave) );
      fprintf( 2, '\t\tInterval 1 sigma %f\n', absolute_sigma(octave,1) );
   end   
   sigma = initial_sigma;
   g = gaussian_filter( sigma );
   filter_size( octave, 1 ) = length(g);
   filter_sigma( octave, 1 ) = sigma;
   DOG_pyr{octave} = zeros(size(gauss_pyr{octave,1},1),size(gauss_pyr{octave,1},2),intervals+2);

   for interval = 2:(intervals+3)      
      sigma_f = sqrt(2^(2/intervals) - 1)*sigma;
      g = gaussian_filter( sigma_f );
      sigma = (2^(1/intervals))*sigma;
      
      % Keep track of the absolute sigma
      absolute_sigma(octave,interval) = sigma * subsample(octave);
      
      % Store the size and standard deviation of the filter for later use
      filter_size(octave,interval) = length(g);
      filter_sigma(octave,interval) = sigma;
      
      if exist('corrsep') == 3
         gauss_pyr{octave,interval} = corrsep( g, g, gauss_pyr{octave,interval-1} );
      else
         gauss_pyr{octave,interval} = conv2( g, g, gauss_pyr{octave,interval-1}, 'same' );
      end      
      DOG_pyr{octave}(:,:,interval-1) = gauss_pyr{octave,interval} - gauss_pyr{octave,interval-1};
      
      if interactive >= 1
         fprintf( 2, '\t\tInterval %d sigma %f\n', interval, absolute_sigma(octave,interval) );
      end              
   end      
   if octave < octaves
      % The gaussian image 2 images from the top of the stack for
      % this octave have be blurred by 2*sigma.  Subsample this image by a 
      % factor of 2 to procuduce the first image of the next octave.
      sz = size(gauss_pyr{octave,intervals+1});
      [X Y] = meshgrid( 1:2:sz(2), 1:2:sz(1) );
      gauss_pyr{octave+1,1} = interp2(gauss_pyr{octave,intervals+1},X,Y,'*nearest'); 
      absolute_sigma(octave+1,1) = absolute_sigma(octave,intervals+1);
      subsample = [subsample subsample(end)*2];
   end      
end
pyr_time = toc;
if interactive >= 1
   fprintf( 2, 'Pryamid processing time %.2f seconds.\n', pyr_time );
end

% Display the gaussian pyramid when in interactive mode
if interactive >= 2
   sz = zeros(1,2);
   sz(2) = (intervals+3)*size(gauss_pyr{1,1},2);
   for octave = 1:octaves
      sz(1) = sz(1) + size(gauss_pyr{octave,1},1);
   end
   pic = zeros(sz);
   y = 1;
   for octave = 1:octaves
      x = 1;
      sz = size(gauss_pyr{octave,1});
      for interval = 1:(intervals + 3)
			pic(y:(y+sz(1)-1),x:(x+sz(2)-1)) = gauss_pyr{octave,interval};		         
         x = x + sz(2);
      end
      y = y + sz(1);
   end
   fig = figure(1);
   clf;
   imshow(pic);
   resizeImageFig( fig, size(pic), 0.25 );
%    fprintf( 2, 'The gaussian pyramid (0.25 scale).\nPress any key to continue.\n' );
%    pause;
%    close(fig)
end

% Display the DOG pyramid when in interactive mode
if interactive >= 2
   sz = zeros(1,2);
   sz(2) = (intervals+2)*size(DOG_pyr{1}(:,:,1),2);
   for octave = 1:octaves
      sz(1) = sz(1) + size(DOG_pyr{octave}(:,:,1),1);
   end
   pic = zeros(sz);
   y = 1;
   for octave = 1:octaves
      x = 1;
      sz = size(DOG_pyr{octave}(:,:,1));
      for interval = 1:(intervals + 2)
			pic(y:(y+sz(1)-1),x:(x+sz(2)-1)) = DOG_pyr{octave}(:,:,interval);		         
         x = x + sz(2);
      end
      y = y + sz(1);
   end
   fig = figure(2);
   clf;
   imshow(pic);
   resizeImageFig( fig, size(pic), 0.25 );
%    fprintf( 2, 'The DOG pyramid (0.25 scale).\nPress any key to continue.\n' );
%    pause;
%    close(fig)
end

% The next step is to detect local maxima in the DOG pyramid.  When
% a maximum is found, two tests are applied before labeling it as a 
% keypoint.  First, it must have sufficient contrast.  Second, it should
% not be and edge point (i.e., the ratio of principal curvatures at the
% extremum should be below a threshold).

% Compute threshold for the ratio of principle curvature test applied to
% the DOG extrema before classifying them as keypoints.
% curvature_threshold = ((curvature_threshold + 1)^2)/curvature_threshold;

% 2nd derivative kernels 
% xx = [ 1 -2  1 ];
% yy = xx';
% xy = [ 1 0 -1; 0 0 0; -1 0 1 ]/4;

% Coordinates of keypoints after each stage of processing for display
% in interactive mode.
% raw_keypoints = [];
% contrast_keypoints = [];
% curve_keypoints = [];

% Detect local maxima in the DOG pyramid
if interactive >= 1
   fprintf( 2, 'Locating keypoints...\n' );
end
% tic;
% loc = cell(size(DOG_pyr)); % boolean maps of keypoints
scale = zeros(1, pose_count);
for i = 1:pose_count
    if interactive >= 1
      fprintf( 2, '\tProcessing pose %d\n', i );
    end
    extrema_found = false;
    for octave = 1:octaves
        if interactive >= 1
          fprintf( 2, '\t\tProcessing octave %d\n', octave );
        end
        x = round(poses(1,i) / subsample(octave));
        y = round(poses(2,i) / subsample(octave));
        if x<=1 || x>=size(DOG_pyr{octave},2) || y<=1 || y>=size(DOG_pyr{octave},1)
            continue;
        end
        for interval = 2:(intervals+1)
            % Check for a max or a min across space and scale
            tmp = DOG_pyr{octave}((y-1):(y+1),(x-1):(x+1),(interval-1):(interval+1));  
            pt_val = tmp(2,2,2);
            if( (pt_val == min(tmp(:))) || (pt_val == max(tmp(:))) )
                scale(i) = absolute_sigma(octave,interval);
                extrema_found = true;
                fprintf( 2, '\tExtrema scale found : %f\n', scale(i) );
                break;
            end
        end
        if extrema_found
            break;
        end
    end
end
% 
% if size(scale,1) > 0
% 	scale = scale(:,3);
% end
fprintf( 2, 'completed\n');
