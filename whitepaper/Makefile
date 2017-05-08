docs: BasicAttentionTokenWhitePaper.tex
	pdflatex BasicAttentionTokenWhitePaper.tex
	bibtex BasicAttentionTokenWhitePaper.aux
	pdflatex BasicAttentionTokenWhitePaper.tex



clean:
	rm BasicAttentionTokenWhitePaper.log	BasicAttentionTokenWhitePaper.toc BasicAttentionTokenWhitePaper.aux	  BasicAttentionTokenWhitePaper.out	 BasicAttentionTokenWhitePaper.blg	  BasicAttentionTokenWhitePaper.run.xml  BasicAttentionTokenWhitePaper-blx.bib  BasicAttentionTokenWhitePaper.bbl wp.tar

tarfile:
	tar -cf wp.tar  BasicAttentionTokenWhitePaper.tex Makefile wp-refs.bib WP_images  

