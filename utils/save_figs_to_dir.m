function save_figs_to_dir(dir_name)
	figlist=findobj('type','figure');
	for i=1:numel(figlist)
		saveas(figlist(i),fullfile(dir_name,['figure' num2str(figlist(i)) '.jpg']));
	end
end
