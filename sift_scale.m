function key_points = sift_scale(im)
	octaves = 4;
	intervals = 2;

    generate_lists(octaves, intervals);
    build_scale_space(im, octaves, intervals);
    key_points = detect_extrema(octaves, intervals);
end

function generate_lists(octaves, intervals)
    global m_gList;
    global m_dogList;
    global m_extrema;
    global m_absSigma;
    
    % Create a 2D array of gaussian blurred images
	m_gList = cell(octaves, intervals+3);

	% Create a 2D array to store images generated after the
	% DoG operation
	m_dogList = cell(octaves, intervals+2);

	% Create a 2D array that will hold if a particular point
	% is an extrema or not
	m_extrema = cell(octaves, intervals);

	% Create a 2D array of decimal numbers. It holds the sigma
	% used to blur the gaussian images.
	m_absSigma = zeros(octaves, intervals+3);
end

function build_scale_space(im, m_numOctaves, m_numIntervals)
	fprintf('Generating scale space...\n');
    
    global m_gList;
    global m_dogList;
    global m_absSigma;

    SIGMA_ANTIALIAS = 0.5;
    SIGMA_PREBLUR = 1.0;
    
    imgTemp = rgb2gray(im);
    imgGray = double(imgTemp) / 255.0;

    % Lowe claims blur the image with a sigma of 0.5 and double it's dimensions
	% to increase the number of stable keypoints
    h = fspecial('gaussian', 3, SIGMA_ANTIALIAS);
    imgGray = imfilter(imgGray, h, 'same');

	% Create an image double the dimensions, resize imgGray and store it in m_gList[0][0]
	m_gList{1,1} = zeros(size(imgGray) * 2);
    for i = 1:size(imgGray,1)
        for j = 1:size(imgGray,2)
            m_gList{1,1}(2*i-1:2*i, 2*j-1:2*j) = imgGray(i,j);
        end
    end

	% Preblur this base image
    h = fspecial('gaussian', 3, SIGMA_PREBLUR);
    m_gList{1,1} = imfilter(m_gList{1,1}, h, 'same');

	initSigma = sqrt(2.0);

	% Keep a track of the sigmas
	m_absSigma(1,1) = initSigma * 0.5;

	% Now for the actual image generation
	for i = 1 : m_numOctaves
		% Reset sigma for each octave
		sigma = initSigma;
		currentSize = size(m_gList{i,1});

		for j = 2 : m_numIntervals + 3
			% Calculate a sigma to blur the current image to get the next one
			sigma_f = sqrt(2.0 ^ (2.0 / m_numIntervals) - 1) * sigma;
            sigma = 2.0 ^ (1.0 / m_numIntervals) * sigma;

			% Store sigma values (to be used later on)
			m_absSigma(i,j) = sigma * 0.5 * (2.0 ^ i);

			% Apply gaussian smoothing)
            h = fspecial('gaussian', 3, sigma_f);
            m_gList{i,j} = imfilter(m_gList{i,j-1}, h, 'same');

			% Calculate the DoG image
			m_dogList{i,j-1} = m_gList{i,j-1} - m_gList{i,j};
        end
        
		% If we're not at the last octave
		if i < m_numOctaves - 1
			% Reduce size to half
			currentSize = currentSize / 2.0;

			% Resample the image
			m_gList{i+1,1} = downsample(m_gList{i,1}, 2);
			m_absSigma(i+1,1) = m_absSigma(i, m_numIntervals);
        end
    end
end

function key_points = detect_extrema(m_numOctaves, m_numIntervals)
	fprintf('Detecting extrema...\n');

    global m_dogList;
    global m_extrema;

    CURVATURE_THRESHOLD = 5.0;
    CONTRAST_THRESHOLD = 0.03;  % in terms of 255

    num = 0;				% Number of keypoins detected
	numRemoved = 0;		% The number of key points rejected because they failed a test

	curvature_threshold = (CURVATURE_THRESHOLD+1)*(CURVATURE_THRESHOLD+1)/CURVATURE_THRESHOLD;

	key_points = [];
    
    % Detect extrema in the DoG images
	for i = 1 : m_numOctaves
		scale = 2.0 ^ i;
		
		for j = 2 : m_numIntervals + 1
			% Allocate memory and set all points to zero ('not key point')
			m_extrema{i,j-1} = zeros(size(m_dogList{i,1}));

			% Images just above and below, in the current octave
			middle = m_dogList{i,j};
			up = m_dogList{i,j+1};
			down = m_dogList{i,j-1};

			for xi = 2 : size(m_dogList{i,j}, 2) - 1
                for yi = 2 : size(m_dogList{i,j}, 1) - 1
					% true if a keypoint is a maxima/minima
					% but needs to be tested for contrast/edge thingy
					justSet = false;
                    
					currentPixel = middle(yi, xi);

					% Check for a maximum
					if currentPixel > middle(yi-1, xi  )	&& ...
                            currentPixel > middle(yi+1, xi  )  && ...
                            currentPixel > middle(yi  , xi-1)  && ...
                            currentPixel > middle(yi  , xi+1)  && ...
                            currentPixel > middle(yi-1, xi-1)	&& ...
                            currentPixel > middle(yi-1, xi+1)	&& ...
                            currentPixel > middle(yi+1, xi+1)	&& ...
                            currentPixel > middle(yi+1, xi-1)	&& ...
                            currentPixel > up(yi  , xi  )      && ...
                            currentPixel > up(yi-1, xi  )      && ...
                            currentPixel > up(yi+1, xi  )      && ...
                            currentPixel > up(yi  , xi-1)      && ...
                            currentPixel > up(yi  , xi+1)      && ...
                            currentPixel > up(yi-1, xi-1)		&& ...
                            currentPixel > up(yi-1, xi+1)		&& ...
                            currentPixel > up(yi+1, xi+1)		&& ...
                            currentPixel > up(yi+1, xi-1)		&& ...
                            currentPixel > down(yi  , xi  )    && ...
                            currentPixel > down(yi-1, xi  )    && ...
                            currentPixel > down(yi+1, xi  )    && ...
                            currentPixel > down(yi  , xi-1)    && ...
                            currentPixel > down(yi  , xi+1)    && ...
                            currentPixel > down(yi-1, xi-1)	&& ...
                            currentPixel > down(yi-1, xi+1)	&& ...
                            currentPixel > down(yi+1, xi+1)	&& ...
                            currentPixel > down(yi+1, xi-1)
						m_extrema{i,j-1}(yi, xi) = 255;
						num = num + 1;
                        key_points = [key_points, [xi*scale/2; yi*scale/2; (i-1)*m_numIntervals+j-2]];  % [x; y; scale]
						justSet = true;
					% Check if it's a minimum
                    elseif (currentPixel < middle(yi-1, xi  )	&& ...
                            currentPixel < middle(yi+1, xi  )  && ...
                            currentPixel < middle(yi  , xi-1)  && ...
                            currentPixel < middle(yi  , xi+1)  && ...
                            currentPixel < middle(yi-1, xi-1)	&& ...
                            currentPixel < middle(yi-1, xi+1)	&& ...
                            currentPixel < middle(yi+1, xi+1)	&& ...
                            currentPixel < middle(yi+1, xi-1)	&& ...
                            currentPixel < up(yi  , xi  )      && ...
                            currentPixel < up(yi-1, xi  )      && ...
                            currentPixel < up(yi+1, xi  )      && ...
                            currentPixel < up(yi  , xi-1)      && ...
                            currentPixel < up(yi  , xi+1)      && ...
                            currentPixel < up(yi-1, xi-1)		&& ...
                            currentPixel < up(yi-1, xi+1)		&& ...
                            currentPixel < up(yi+1, xi+1)		&& ...
                            currentPixel < up(yi+1, xi-1)		&& ...
                            currentPixel < down(yi  , xi  )    && ...
                            currentPixel < down(yi-1, xi  )    && ...
                            currentPixel < down(yi+1, xi  )    && ...
                            currentPixel < down(yi  , xi-1)    && ...
                            currentPixel < down(yi  , xi+1)    && ...
                            currentPixel < down(yi-1, xi-1)	&& ...
                            currentPixel < down(yi-1, xi+1)	&& ...
                            currentPixel < down(yi+1, xi+1)	&& ...
                            currentPixel < down(yi+1, xi-1)   )
						m_extrema{i,j-1}(yi, xi) = 255;
						num = num + 1;
                        key_points = [key_points, [xi*scale/2; yi*scale/2; (i-1)*m_numIntervals+j-2]];  % [x; y; scale]
						justSet = true;
                    end
					% The contrast check
					if justSet && fabs(middle(yi, xi)) < CONTRAST_THRESHOLD
						m_extrema{i,j-1}(yi, xi) = 0;
						num = num - 1;
						numRemoved = numRemoved + 1;

						justSet = false;
                    end
					% The edge check
					if justSet
						dxx = (middle(yi-1, xi) + middle(yi+1, xi) - 2.0*middle(yi, xi));
						dyy = (middle(yi, xi-1) + middle(yi, xi+1) - 2.0*middle(yi, xi));
						dxy = (middle(yi-1, xi-1) + middle(yi+1, xi+1) - middle(yi+1, xi-1) - middle(yi-1, xi+1)) / 4.0;

						trH = dxx + dyy;
						detH = dxx*dyy - dxy*dxy;

						curvature_ratio = trH * trH / detH;
						%fprintf('Threshold: %f - Ratio: %f\n', curvature_threshold, curvature_ratio);
						if detH < 0 || curvature_ratio > curvature_threshold
							m_extrema{i,j-1}(yi, xi) = 0;
							num = num - 1;
							numRemoved = numRemoved + 1;

							justSet = false;
                        end
                    end
                end
            end
        end
    end

	m_numKeypoints = num;
	fprintf('Found %d keypoints\n', num);
	fprintf('Rejected %d keypoints\n', numRemoved);
end
