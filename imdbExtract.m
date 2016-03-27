function [images,meta] = imdbExtract(path,varargin)
folders = dir(path);
if exist(fullfile(path,'imdb.mat'),'file')
    fprintf('The "imdb.mat" file was already created. Check it. \n');
    return;
else
    fprintf('Extracting data from --%s-- into a ".mat" file \n', path);
end


images = struct('data', [], 'data_mean', [], 'labels', [], 'set', []);
meta.sets = {'train', 'test', 'val'}; meta.classes = {};

total_images = 0;
for f=3:numel(folders)
    if( folders(f).isdir )
        images_f = dir( fullfile(path,folders(f).name) );
        if f == 3
            I = imread( fullfile(path,folders(f).name,images_f(3).name) );
            imagesize = [size(I,1),size(I,2),size(I,3)];
			
			if nargin > 1
				if strcmp(varargin{1},'min')
					imagesize(1:2) = min(imagesize(1:2));
                end
                if strcmp(varargin{1},'crop')
                    imagesize(1:2) = varargin{2};
                end
			end
        end		
		
        n_images = numel(images_f)-2;
        total_images = total_images + n_images;
        
        set = [ones(1,n_images-2*floor(0.1*n_images)), ... 
            2*ones(1,floor(0.1*n_images)),...
            3*ones(1,floor(0.1*n_images))];

        images.labels = [images.labels uint8((f-3)*ones(1,n_images))];
        images.set = [images.set uint8(set)];
        meta.classes{f-2} = folders(f).name;
    end
end

images.data = zeros(imagesize(1),imagesize(2),imagesize(3),total_images,'uint8');

n_images = 0;
for f=3:numel(folders)
    images_f = dir( fullfile(path,folders(f).name) );
    for i=3:numel(images_f)
        n_images = n_images + 1;

        I = imread( fullfile(path,folders(f).name,images_f(i).name) );        
        rows = min(imagesize(1), size(I,1));
        cols = min(imagesize(2), size(I,2));
		
		if nargin > 1
			if strcmp(varargin{1},'min') || strcmp(varargin{1},'crop')
				images.data(1:rows, 1:cols, :, n_images) = uint8( I(1:rows, 1:cols, :) );
			end
		else
			images.data(:,:,:,n_images) = uint8(I);
		end
    end
    fprintf('Saving "%s" classes.\n',folders(f).name);
end

images.data_mean =  single(mean(images.data(:,:,:,images.set == 1), 4));
%Converting uint8 to single requires 4x more memory which is unfeaseable
%images.data = bsxfun(@minus, single(images.data), images.data_mean);

imdb.images = images;
imdb.meta = meta;

save(fullfile(path,'imdb.mat'), '-struct', 'imdb') ;
info = whos('imdb'); info = info.bytes/2^20;
fprintf('File saved succesfully File size = %f MB.',info);
end