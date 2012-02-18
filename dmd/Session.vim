let SessionLoad = 1
if &cp | set nocp | endif
let s:cpo_save=&cpo
set cpo&vim
inoremap <C-Down> <Down>
inoremap <C-Up> <Up>
imap <C-Left> :bprevious
imap <C-Right> :bnext
imap <F5> :so run
imap <F4> :so vimbuild
imap <D-BS> 
imap <M-BS> 
imap <M-Down> }
inoremap <D-Down> <C-End>
imap <M-Up> {
inoremap <D-Up> <C-Home>
noremap! <M-Right> <C-Right>
noremap! <D-Right> <End>
noremap! <M-Left> <C-Left>
noremap! <D-Left> <Home>
map! <D-v> *
noremap  <S-Down>
noremap  <S-Up>
nnoremap : :  
noremap ; :
map Q q
map [[ ?{w99[{
map \c o/+  +/<Left><Left><Left>
map ][ /}b99]}
nmap gx <Plug>NetrwBrowseX
map <F7> :w:Rexplore
map <F10> :cc
map <F9> @w<F8>
map <F8> :w:cn
noremap <S-Right> zL
noremap <S-Left> zH
noremap <S-Down> 
noremap <S-Up> 
nmap <C-Left> :w:bprevious
nmap <C-Right> :w:bnext
map <F6> :e %:p:h:cd %
nmap <F5> :so run
map <F4> :so ~/zd/vimbuild
map <F3>  
map <F2> :if @% == $HOME."/.gvimrc":wq:else:sp ~/.gvimrcendif
noremap <F1> :help 
map <M-Down> }
noremap <D-Down> <C-End>
map <M-Up> {
noremap <D-Up> <C-Home>
noremap <M-Right> <C-Right>
noremap <D-Right> <End>
noremap <M-Left> <C-Left>
noremap <D-Left> <Home>
nnoremap <silent> <Plug>NetrwBrowseX :call netrw#NetrwBrowseX(expand("<cWORD>"),0)
vmap <BS> "-d
vmap <D-x> "*d
vmap <D-c> "*y
vmap <D-v> "-d"*P
nmap <D-v> "*P
let &cpo=s:cpo_save
unlet s:cpo_save
set autoindent
set background=dark
set backspace=indent,eol,start
set cpoptions=BceFs
set expandtab
set fileencodings=ucs-bom,utf-8,default,latin1
set foldlevelstart=99
set guifont=Anonymous:h17
set guioptions=egmrLt
set guitablabel=%M%t
set helplang=en
set hlsearch
set incsearch
set langmenu=none
set laststatus=2
set listchars=eol:$,precedes:<,extends:>
set makeprg=~/zd/zddmd/build.sh
set mouse=a
set printexpr=system('open\ -a\ Preview\ '.v:fname_in)\ +\ v:shell_error
set report=10000
set ruler
set shiftwidth=4
set showmatch
set sidescroll=5
set smarttab
set softtabstop=3
set noswapfile
set tabstop=3
set termencoding=utf-8
set textwidth=80
set winheight=25
set winwidth=72
let s:so_save = &so | let s:siso_save = &siso | set so=0 siso=0
let v:this_session=expand("<sfile>:p")
silent only
cd ~/zd/zddmd/dmd
if expand('%') == '' && !&modified && line('$') <= 1 && getline(1) == ''
  let s:wipebuf = bufnr('%')
endif
set shortmess=aoO
badd +64 ~/zd/zd.d
badd +84 ~/.gvimrc
badd +1 ~/zd/vimbuild
badd +3 ~/zd/build
badd +1 ~/zd/run
badd +1 ~/zd/build.zd
badd +32 ~/zd/ceres.d
badd +1 ~/zd/zdevent.d
badd +2 ~/zd/zdSDL.d
badd +1142 ~/Downloads/libtcod\ 1.5.1\ OSX/samples_cpp.cpp
badd +125 Lexer.d
badd +5665 Parser.d
badd +35 ~/zd/zddmd/notes.zd
badd +29 ~/zd/zddmd/main.d
badd +1 ConditionsAll.d
badd +1 InitializersAll.d
badd +30 StatementsAll.d
badd +98 Module.d
badd +139 Token.d
badd +0 ~/.ssh/id_rsa.pub
badd +30 ~/.ssh/id_rsa
badd +1 ~/.ssh/known_hosts
badd +2 ~/zd/ddmd-clean/README
badd +3 ~/zd/ddmd-clean/build.sh
badd +37 ~/zd/ddmd-clean/buildHelper.d
badd +18 ~/zd/ddmd-clean/ddmdmain.d
badd +10 ~/zd/ddmd-clean/NOTES
badd +30 ~/zd/ddmd-clean/build_zddmd.d
badd +1 ~/zd/ddmd-clean/test.d
badd +17 ~/zd/ddmd-clean/zdtrashfile.d
badd +46 ~/zd/ddmd-clean/dmd/Lexer.d
badd +0 ~/zd/Session.vim
args ~/zd/zd.d
edit ~/zd/zddmd/notes.zd
set splitbelow splitright
set nosplitbelow
set nosplitright
wincmd t
set winheight=1 winwidth=1
argglobal
setlocal keymap=
setlocal noarabic
setlocal autoindent
setlocal balloonexpr=
setlocal nobinary
setlocal bufhidden=
setlocal buflisted
setlocal buftype=
setlocal nocindent
setlocal cinkeys=0{,0},0),:,0#,!^F,o,O,e
setlocal cinoptions=
setlocal cinwords=if,else,while,do,for,switch
setlocal colorcolumn=
setlocal comments=s1:/*,mb:*,ex:*/,://,b:#,:%,:XCOMM,n:>,fb:-
setlocal commentstring=/*%s*/
setlocal complete=.,w,b,u,t,i
setlocal concealcursor=
setlocal conceallevel=0
setlocal completefunc=
setlocal nocopyindent
setlocal cryptmethod=
setlocal nocursorbind
setlocal nocursorcolumn
set cursorline
setlocal cursorline
setlocal define=
setlocal dictionary=
setlocal nodiff
setlocal equalprg=
setlocal errorformat=
setlocal expandtab
if &filetype != ''
setlocal filetype=
endif
setlocal foldcolumn=0
setlocal foldenable
setlocal foldexpr=0
setlocal foldignore=#
setlocal foldlevel=99
setlocal foldmarker={{{,}}}
set foldmethod=indent
setlocal foldmethod=indent
setlocal foldminlines=1
setlocal foldnestmax=20
setlocal foldtext=foldtext()
setlocal formatexpr=
setlocal formatoptions=tcq
setlocal formatlistpat=^\\s*\\d\\+[\\]:.)}\\t\ ]\\s*
setlocal grepprg=
setlocal iminsert=2
setlocal imsearch=2
setlocal include=
setlocal includeexpr=
setlocal indentexpr=
setlocal indentkeys=0{,0},:,0#,!^F,o,O,e
setlocal noinfercase
setlocal iskeyword=@,48-57,_,192-255
setlocal keywordprg=
setlocal nolinebreak
setlocal nolisp
setlocal nolist
setlocal nomacmeta
setlocal makeprg=
setlocal matchpairs=(:),{:},[:]
setlocal modeline
setlocal modifiable
setlocal nrformats=octal,hex
set number
setlocal number
setlocal numberwidth=4
setlocal omnifunc=
setlocal path=
setlocal nopreserveindent
setlocal nopreviewwindow
setlocal quoteescape=\\
setlocal noreadonly
setlocal norelativenumber
setlocal norightleft
setlocal rightleftcmd=search
setlocal noscrollbind
setlocal shiftwidth=4
setlocal noshortname
setlocal nosmartindent
setlocal softtabstop=3
setlocal nospell
setlocal spellcapcheck=
setlocal spellfile=
setlocal spelllang=en
setlocal statusline=
setlocal suffixesadd=
setlocal noswapfile
setlocal synmaxcol=3000
if &syntax != ''
setlocal syntax=
endif
setlocal tabstop=3
setlocal tags=
setlocal textwidth=108
setlocal thesaurus=
setlocal noundofile
setlocal nowinfixheight
setlocal nowinfixwidth
setlocal wrap
setlocal wrapmargin=0
let s:l = 2 - ((1 * winheight(0) + 15) / 30)
if s:l < 1 | let s:l = 1 | endif
exe s:l
normal! zt
2
normal! 0
lcd ~/zd/zddmd/dmd
tabedit ~/zd/zddmd/dmd/Module.d
set splitbelow splitright
set nosplitbelow
set nosplitright
wincmd t
set winheight=1 winwidth=1
argglobal
setlocal keymap=
setlocal noarabic
setlocal autoindent
setlocal balloonexpr=
setlocal nobinary
setlocal bufhidden=
setlocal buflisted
setlocal buftype=
setlocal nocindent
setlocal cinkeys=0{,0},0),:,0#,!^F,o,O,e
setlocal cinoptions=
setlocal cinwords=if,else,while,do,for,switch
setlocal colorcolumn=
setlocal comments=s1:/*,mb:*,ex:*/,://,b:#,:%,:XCOMM,n:>,fb:-
setlocal commentstring=/*%s*/
setlocal complete=.,w,b,u,t,i
setlocal concealcursor=
setlocal conceallevel=0
setlocal completefunc=
setlocal nocopyindent
setlocal cryptmethod=
setlocal nocursorbind
setlocal nocursorcolumn
set cursorline
setlocal cursorline
setlocal define=
setlocal dictionary=
setlocal nodiff
setlocal equalprg=
setlocal errorformat=
setlocal expandtab
if &filetype != 'd'
setlocal filetype=d
endif
setlocal foldcolumn=0
setlocal foldenable
setlocal foldexpr=0
setlocal foldignore=#
setlocal foldlevel=99
setlocal foldmarker={{{,}}}
set foldmethod=indent
setlocal foldmethod=indent
setlocal foldminlines=1
setlocal foldnestmax=20
setlocal foldtext=foldtext()
setlocal formatexpr=
setlocal formatoptions=tcq
setlocal formatlistpat=^\\s*\\d\\+[\\]:.)}\\t\ ]\\s*
setlocal grepprg=
setlocal iminsert=2
setlocal imsearch=2
setlocal include=
setlocal includeexpr=
setlocal indentexpr=
setlocal indentkeys=0{,0},:,0#,!^F,o,O,e
setlocal noinfercase
setlocal iskeyword=@,48-57,_,192-255
setlocal keywordprg=
setlocal nolinebreak
setlocal nolisp
setlocal nolist
setlocal nomacmeta
setlocal makeprg=
setlocal matchpairs=(:),{:},[:]
setlocal modeline
setlocal modifiable
setlocal nrformats=octal,hex
set number
setlocal number
setlocal numberwidth=4
setlocal omnifunc=
setlocal path=
setlocal nopreserveindent
setlocal nopreviewwindow
setlocal quoteescape=\\
setlocal noreadonly
setlocal norelativenumber
setlocal norightleft
setlocal rightleftcmd=search
setlocal noscrollbind
setlocal shiftwidth=4
setlocal noshortname
setlocal nosmartindent
setlocal softtabstop=3
setlocal nospell
setlocal spellcapcheck=
setlocal spellfile=
setlocal spelllang=en
setlocal statusline=
setlocal suffixesadd=
setlocal noswapfile
setlocal synmaxcol=3000
if &syntax != 'd'
setlocal syntax=d
endif
setlocal tabstop=3
setlocal tags=
setlocal textwidth=108
setlocal thesaurus=
setlocal noundofile
setlocal nowinfixheight
setlocal nowinfixwidth
setlocal wrap
setlocal wrapmargin=0
31
normal zo
115
normal zo
31
normal zo
let s:l = 176 - ((28 * winheight(0) + 15) / 30)
if s:l < 1 | let s:l = 1 | endif
exe s:l
normal! zt
176
normal! 0
lcd ~/zd
tabedit ~/zd/zddmd/dmd/Parser.d
set splitbelow splitright
set nosplitbelow
set nosplitright
wincmd t
set winheight=1 winwidth=1
argglobal
setlocal keymap=
setlocal noarabic
setlocal autoindent
setlocal balloonexpr=
setlocal nobinary
setlocal bufhidden=
setlocal buflisted
setlocal buftype=
setlocal nocindent
setlocal cinkeys=0{,0},0),:,0#,!^F,o,O,e
setlocal cinoptions=
setlocal cinwords=if,else,while,do,for,switch
setlocal colorcolumn=
setlocal comments=s1:/*,mb:*,ex:*/,://,b:#,:%,:XCOMM,n:>,fb:-
setlocal commentstring=/*%s*/
setlocal complete=.,w,b,u,t,i
setlocal concealcursor=
setlocal conceallevel=0
setlocal completefunc=
setlocal nocopyindent
setlocal cryptmethod=
setlocal nocursorbind
setlocal nocursorcolumn
set cursorline
setlocal cursorline
setlocal define=
setlocal dictionary=
setlocal nodiff
setlocal equalprg=
setlocal errorformat=
setlocal expandtab
if &filetype != 'd'
setlocal filetype=d
endif
setlocal foldcolumn=0
setlocal foldenable
setlocal foldexpr=0
setlocal foldignore=#
setlocal foldlevel=99
setlocal foldmarker={{{,}}}
set foldmethod=indent
setlocal foldmethod=indent
setlocal foldminlines=1
setlocal foldnestmax=20
setlocal foldtext=foldtext()
setlocal formatexpr=
setlocal formatoptions=tcq
setlocal formatlistpat=^\\s*\\d\\+[\\]:.)}\\t\ ]\\s*
setlocal grepprg=
setlocal iminsert=2
setlocal imsearch=2
setlocal include=
setlocal includeexpr=
setlocal indentexpr=
setlocal indentkeys=0{,0},:,0#,!^F,o,O,e
setlocal noinfercase
setlocal iskeyword=@,48-57,_,192-255
setlocal keywordprg=
setlocal nolinebreak
setlocal nolisp
setlocal nolist
setlocal nomacmeta
setlocal makeprg=
setlocal matchpairs=(:),{:},[:]
setlocal modeline
setlocal modifiable
setlocal nrformats=octal,hex
set number
setlocal number
setlocal numberwidth=4
setlocal omnifunc=
setlocal path=
setlocal nopreserveindent
setlocal nopreviewwindow
setlocal quoteescape=\\
setlocal noreadonly
setlocal norelativenumber
setlocal norightleft
setlocal rightleftcmd=search
setlocal noscrollbind
setlocal shiftwidth=4
setlocal noshortname
setlocal nosmartindent
setlocal softtabstop=3
setlocal nospell
setlocal spellcapcheck=
setlocal spellfile=
setlocal spelllang=en
setlocal statusline=
setlocal suffixesadd=
setlocal noswapfile
setlocal synmaxcol=3000
if &syntax != 'd'
setlocal syntax=d
endif
setlocal tabstop=3
setlocal tags=
setlocal textwidth=108
setlocal thesaurus=
setlocal noundofile
setlocal nowinfixheight
setlocal nowinfixwidth
setlocal wrap
setlocal wrapmargin=0
213
normal zo
228
normal zo
233
normal zo
239
normal zo
241
normal zo
241
normal zo
239
normal zo
265
normal zo
265
normal zo
233
normal zo
228
normal zo
213
normal zo
298
normal zo
307
normal zo
324
normal zo
349
normal zo
361
normal zo
362
normal zo
364
normal zo
362
normal zo
361
normal zo
324
normal zo
307
normal zo
298
normal zo
392
normal zo
392
normal zo
392
normal zo
392
normal zo
446
normal zo
455
normal zo
455
normal zo
446
normal zo
392
normal zo
536
normal zo
597
normal zo
613
normal zo
536
normal zo
627
normal zo
646
normal zo
646
normal zo
671
normal zo
671
normal zo
699
normal zo
701
normal zo
703
normal zo
699
normal zo
722
normal zo
724
normal zo
726
normal zo
722
normal zo
627
normal zo
741
normal zo
741
normal zo
766
normal zo
392
normal zo
784
normal zo
788
normal zo
798
normal zo
803
normal zo
807
normal zo
803
normal zo
814
normal zo
788
normal zo
784
normal zo
392
normal zo
929
normal zo
929
normal zo
982
normal zo
994
normal zo
998
normal zo
1018
normal zo
1033
normal zo
1035
normal zo
1033
normal zo
1042
normal zo
1044
normal zo
1046
normal zo
1042
normal zo
1051
normal zo
1055
normal zo
1061
normal zo
1066
normal zo
1074
normal zo
1087
normal zo
1093
normal zo
1098
normal zo
1108
normal zo
998
normal zo
994
normal zo
982
normal zo
1132
normal zo
1146
normal zo
1178
normal zo
1191
normal zo
1178
normal zo
1146
normal zo
1240
normal zo
1248
normal zo
1250
normal zo
1250
normal zo
1248
normal zo
1240
normal zo
1242
normal zo
1250
normal zo
1252
normal zo
1264
normal zo
1267
normal zo
1277
normal zo
1284
normal zo
1277
normal zo
1297
normal zo
1267
normal zo
1264
normal zo
1252
normal zo
1311
normal zo
1250
normal zo
1242
normal zo
1328
normal zo
1333
normal zo
1334
normal zo
1333
normal zo
1328
normal zo
1406
normal zo
1406
normal zo
1428
normal zo
1435
normal zo
1440
normal zo
1428
normal zo
1503
normal zo
1507
normal zo
1507
normal zo
1524
normal zo
1503
normal zo
1534
normal zo
1540
normal zo
1546
normal zo
1540
normal zo
1534
normal zo
1574
normal zo
1574
normal zo
1608
normal zo
1613
normal zo
1629
normal zo
1629
normal zo
1608
normal zo
1667
normal zo
1687
normal zo
1705
normal zo
1725
normal zo
1745
normal zo
1766
normal zo
1766
normal zo
1788
normal zo
1799
normal zo
1805
normal zo
1824
normal zo
1824
normal zo
1938
normal zo
1938
normal zo
1940
normal zo
1960
normal zo
1940
normal zo
1976
normal zo
1938
normal zo
1938
normal zo
1995
normal zo
2024
normal zo
2029
normal zo
2029
normal zo
2024
normal zo
1995
normal zo
1997
normal zo
2006
normal zo
2010
normal zo
2014
normal zo
2019
normal zo
2023
normal zo
2026
normal zo
2031
normal zo
2053
normal zo
2066
normal zo
2031
normal zo
2026
normal zo
2085
normal zo
1997
normal zo
2091
normal zo
2091
normal zo
2093
normal zo
2105
normal zo
2109
normal zo
2114
normal zo
2109
normal zo
2128
normal zo
2129
normal zo
2135
normal zo
2139
normal zo
2135
normal zo
2143
normal zo
2145
normal zo
2128
normal zo
2153
normal zo
2158
normal zo
2164
normal zo
2176
normal zo
2180
normal zo
2185
normal zo
2093
normal zo
2205
normal zo
2207
normal zo
2211
normal zo
2214
normal zo
2215
normal zo
2219
normal zo
2223
normal zo
2227
normal zo
2231
normal zo
2214
normal zo
2235
normal zo
2238
normal zo
2235
normal zo
2242
normal zo
2211
normal zo
2207
normal zo
2205
normal zo
2251
normal zo
2261
normal zo
2264
normal zo
2273
normal zo
2278
normal zo
2298
normal zo
2305
normal zo
2312
normal zo
2315
normal zo
2312
normal zo
2323
normal zo
2298
normal zo
2261
normal zo
2337
normal zo
2340
normal zo
2251
normal zo
2347
normal zo
2356
normal zo
2403
normal zo
2403
normal zo
2413
normal zo
2347
normal zo
2349
normal zo
2356
normal zo
2358
normal zo
2366
normal zo
2367
normal zo
2367
normal zo
2367
normal zo
2372
normal zo
2366
normal zo
2379
normal zo
2387
normal zo
2387
normal zo
2387
normal zo
2389
normal zo
2398
normal zo
2405
normal zo
2409
normal zo
2405
normal zo
2415
normal zo
2349
normal zo
2420
normal zo
2473
normal zo
2483
normal zo
2473
normal zo
2420
normal zo
2422
normal zo
2429
normal zo
2453
normal zo
2429
normal zo
2457
normal zo
2464
normal zo
2467
normal zo
2457
normal zo
2473
normal zo
2475
normal zo
2479
normal zo
2485
normal zo
2496
normal zo
2475
normal zo
2502
normal zo
2507
normal zo
2512
normal zo
2525
normal zo
2534
normal zo
2548
normal zo
2560
normal zo
2422
normal zo
2567
normal zo
2567
normal zo
2569
normal zo
2572
normal zo
2574
normal zo
2574
normal zo
2572
normal zo
2569
normal zo
2688
normal zo
2690
normal zo
2688
normal zo
2692
normal zo
2699
normal zo
2732
normal zo
2737
normal zo
2739
normal zo
2745
normal zo
2749
normal zo
2754
normal zo
2761
normal zo
2768
normal zo
2745
normal zo
2739
normal zo
2789
normal zo
2789
normal zo
2737
normal zo
2732
normal zo
2699
normal zo
2902
normal zo
2904
normal zo
2923
normal zo
2930
normal zo
2940
normal zo
2923
normal zo
2940
normal zo
2944
normal zo
2944
normal zo
2944
normal zo
2953
normal zo
2954
normal zo
2953
normal zo
2960
normal zo
2961
normal zo
2960
normal zo
2966
normal zo
2967
normal zo
2966
normal zo
2972
normal zo
2973
normal zo
2972
normal zo
2904
normal zo
2993
normal zo
2994
normal zo
3001
normal zo
3003
normal zo
3001
normal zo
3010
normal zo
3019
normal zo
3019
normal zo
3019
normal zo
3022
normal zo
3027
normal zo
2993
normal zo
3062
normal zo
3078
normal zo
3087
normal zo
3090
normal zo
3098
normal zo
3105
normal zo
3078
normal zo
3121
normal zo
3124
normal zo
3126
normal zo
3127
normal zo
3126
normal zo
3124
normal zo
3131
normal zo
3144
normal zo
3144
normal zo
3152
normal zo
3156
normal zo
3152
normal zo
3121
normal zo
3164
normal zo
3177
normal zo
3184
normal zo
3164
normal zo
3062
normal zo
2902
normal zo
3211
normal zo
3213
normal zo
3240
normal zo
3240
normal zo
3247
normal zo
3247
normal zo
3213
normal zo
3211
normal zo
3270
normal zo
3288
normal zo
3295
normal zo
3288
normal zo
3350
normal zo
3350
normal zo
3358
normal zo
3363
normal zo
3375
normal zo
3380
normal zo
3375
normal zo
3358
normal zo
3270
normal zo
3420
normal zo
3423
normal zo
3426
normal zo
3430
normal zo
3426
normal zo
3437
normal zo
3423
normal zo
3453
normal zo
3453
normal zo
3460
normal zo
3472
normal zo
3475
normal zo
3460
normal zo
3483
normal zo
3500
normal zo
3516
normal zo
3528
normal zo
3536
normal zo
3550
normal zo
3592
normal zo
3420
normal zo
3609
normal zo
3609
normal zo
3640
normal zo
3650
normal zo
3609
normal zo
3659
normal zo
3671
normal zo
3685
normal zo
3704
normal zo
3659
normal zo
3727
normal zo
3727
normal zo
3765
normal zo
3777
normal zo
3808
normal zo
3855
normal zo
3808
normal zo
3819
normal zo
3825
normal zo
3829
normal zo
3825
normal zo
3837
normal zo
3838
normal zo
3837
normal zo
3846
normal zo
3846
normal zo
3846
normal zo
3857
normal zo
3861
normal zo
3819
normal zo
3873
normal zo
3878
normal zo
3873
normal zo
3892
normal zo
3892
normal zo
3904
normal zo
3904
normal zo
3920
normal zo
3935
normal zo
3935
normal zo
3968
normal zo
3986
normal zo
3999
normal zo
4006
normal zo
4041
normal zo
4043
normal zo
3999
normal zo
4051
normal zo
4051
normal zo
4059
normal zo
4062
normal zo
4077
normal zo
4077
normal zo
4059
normal zo
4068
normal zo
4083
normal zo
4114
normal zo
4083
normal zo
4068
normal zo
4150
normal zo
4151
normal zo
4150
normal zo
3609
normal zo
4169
normal zo
4183
normal zo
4184
normal zo
4184
normal zo
4268
normal zo
4309
normal zo
4310
normal zo
4310
normal zo
4309
normal zo
4268
normal zo
4359
normal zo
4369
normal zo
4183
normal zo
4169
normal zo
4381
normal zo
4384
normal zo
4387
normal zo
4384
normal zo
4381
normal zo
4627
normal zo
4638
normal zo
4641
normal zo
4641
normal zo
4638
normal zo
4724
normal zo
4726
normal zo
4728
normal zo
4731
normal zo
4731
normal zo
4728
normal zo
4793
normal zo
4726
normal zo
4724
normal zo
4627
normal zo
4631
normal zo
4633
normal zo
4640
normal zo
4644
normal zo
4647
normal zo
4656
normal zo
4660
normal zo
4665
normal zo
4670
normal zo
4673
normal zo
4676
normal zo
4678
normal zo
4676
normal zo
4681
normal zo
4670
normal zo
4688
normal zo
4697
normal zo
4700
normal zo
4707
normal zo
4709
normal zo
4707
normal zo
4713
normal zo
4722
normal zo
4647
normal zo
4644
normal zo
4730
normal zo
4732
normal zo
4734
normal zo
4737
normal zo
4741
normal zo
4745
normal zo
4750
normal zo
4752
normal zo
4754
normal zo
4750
normal zo
4737
normal zo
4763
normal zo
4766
normal zo
4768
normal zo
4775
normal zo
4778
normal zo
4782
normal zo
4768
normal zo
4766
normal zo
4734
normal zo
4799
normal zo
4732
normal zo
4730
normal zo
4633
normal zo
4810
normal zo
4810
normal zo
5087
normal zo
5200
normal zo
5208
normal zo
5211
normal zo
5213
normal zo
5214
normal zo
5213
normal zo
5211
normal zo
5208
normal zo
5200
normal zo
5474
normal zo
5474
normal zo
5087
normal zo
5092
normal zo
5092
normal zo
5092
normal zo
5097
normal zo
5105
normal zo
5097
normal zo
5115
normal zo
5124
normal zo
5125
normal zo
5129
normal zo
5134
normal zo
5137
normal zo
5129
normal zo
5125
normal zo
5124
normal zo
5146
normal zo
5153
normal zo
5158
normal zo
5163
normal zo
5168
normal zo
5173
normal zo
5178
normal zo
5183
normal zo
5188
normal zo
5193
normal zo
5198
normal zo
5203
normal zo
5208
normal zo
5213
normal zo
5218
normal zo
5224
normal zo
5231
normal zo
5236
normal zo
5241
normal zo
5246
normal zo
5251
normal zo
5256
normal zo
5262
normal zo
5270
normal zo
5273
normal zo
5275
normal zo
5276
normal zo
5275
normal zo
5273
normal zo
5270
normal zo
5262
normal zo
5312
normal zo
5314
normal zo
5325
normal zo
5332
normal zo
5337
normal zo
5341
normal zo
5332
normal zo
5350
normal zo
5373
normal zo
5383
normal zo
5387
normal zo
5391
normal zo
5407
normal zo
5412
normal zo
5387
normal zo
5417
normal zo
5418
normal zo
5421
normal zo
5417
normal zo
5427
normal zo
5383
normal zo
5431
normal zo
5373
normal zo
5439
normal zo
5455
normal zo
5465
normal zo
5474
normal zo
5487
normal zo
5498
normal zo
5520
normal zo
5522
normal zo
5487
normal zo
5527
normal zo
5533
normal zo
5536
normal zo
5553
normal zo
5558
normal zo
5559
normal zo
5562
normal zo
5568
normal zo
5569
normal zo
5571
normal zo
5574
normal zo
5577
normal zo
5578
normal zo
5581
normal zo
5584
normal zo
5587
normal zo
5590
normal zo
5592
normal zo
5577
normal zo
5574
normal zo
5596
normal zo
5568
normal zo
5558
normal zo
5536
normal zo
5115
normal zo
5615
normal zo
5621
normal zo
5619
normal zo
5627
normal zo
5628
normal zo
5636
normal zo
5628
normal zo
5627
normal zo
5619
normal zo
5621
normal zo
5615
normal zo
5623
normal zo
5625
normal zo
5630
normal zo
5631
normal zo
5637
normal zo
5643
normal zo
5649
normal zo
5655
normal zo
5661
normal zo
5667
normal zo
5673
normal zo
5679
normal zo
5685
normal zo
5689
normal zo
5690
normal zo
5698
normal zo
5703
normal zo
5708
normal zo
5713
normal zo
5718
normal zo
5722
normal zo
5722
normal zo
5722
normal zo
5724
normal zo
5690
normal zo
5728
normal zo
5728
normal zo
5728
normal zo
5730
normal zo
5689
normal zo
5630
normal zo
5625
normal zo
5623
normal zo
5736
normal zo
5736
normal zo
5736
normal zo
5736
normal zo
5742
normal zo
5736
normal zo
5736
normal zo
5751
normal zo
5753
normal zo
5755
normal zo
5758
normal zo
5761
normal zo
5813
normal zo
5814
normal zo
5814
normal zo
5813
normal zo
5761
normal zo
5758
normal zo
5755
normal zo
5753
normal zo
5751
normal zo
5736
normal zo
5736
normal zo
5846
normal zo
5846
normal zo
5876
normal zo
5876
normal zo
5846
normal zo
5851
normal zo
5857
normal zo
5846
normal zo
5868
normal zo
5870
normal zo
5877
normal zo
5882
normal zo
5902
normal zo
5906
normal zo
5933
normal zo
5938
normal zo
5958
normal zo
5938
normal zo
5877
normal zo
5870
normal zo
6004
normal zo
6011
normal zo
6013
normal zo
6014
normal zo
6017
normal zo
6020
normal zo
6023
normal zo
6013
normal zo
6011
normal zo
6028
normal zo
6004
normal zo
6030
normal zo
6032
normal zo
6039
normal zo
6041
normal zo
6039
normal zo
6032
normal zo
6053
normal zo
6055
normal zo
6058
normal zo
6060
normal zo
6063
normal zo
6227
normal zo
6227
normal zo
6229
normal zo
6237
normal zo
6229
normal zo
6246
normal zo
6283
normal zo
6287
normal zo
6287
normal zo
6307
normal zo
6313
normal zo
6307
normal zo
6324
normal zo
6283
normal zo
6288
normal zo
6294
normal zo
6296
normal zo
6299
normal zo
6302
normal zo
6307
normal zo
6302
normal zo
6299
normal zo
6288
normal zo
6316
normal zo
6318
normal zo
6328
normal zo
6334
normal zo
6336
normal zo
6340
normal zo
6347
normal zo
6352
normal zo
6334
normal zo
6369
normal zo
6375
normal zo
6380
normal zo
6369
normal zo
6386
normal zo
6394
normal zo
6318
normal zo
6401
normal zo
6403
normal zo
let s:l = 1550 - ((17 * winheight(0) + 15) / 30)
if s:l < 1 | let s:l = 1 | endif
exe s:l
normal! zt
1550
normal! 026l
lcd ~/zd/zddmd/dmd
tabedit ~/zd/zddmd/dmd/Token.d
set splitbelow splitright
set nosplitbelow
set nosplitright
wincmd t
set winheight=1 winwidth=1
argglobal
setlocal keymap=
setlocal noarabic
setlocal autoindent
setlocal balloonexpr=
setlocal nobinary
setlocal bufhidden=
setlocal buflisted
setlocal buftype=
setlocal nocindent
setlocal cinkeys=0{,0},0),:,0#,!^F,o,O,e
setlocal cinoptions=
setlocal cinwords=if,else,while,do,for,switch
setlocal colorcolumn=
setlocal comments=s1:/*,mb:*,ex:*/,://,b:#,:%,:XCOMM,n:>,fb:-
setlocal commentstring=/*%s*/
setlocal complete=.,w,b,u,t,i
setlocal concealcursor=
setlocal conceallevel=0
setlocal completefunc=
setlocal nocopyindent
setlocal cryptmethod=
setlocal nocursorbind
setlocal nocursorcolumn
set cursorline
setlocal cursorline
setlocal define=
setlocal dictionary=
setlocal nodiff
setlocal equalprg=
setlocal errorformat=
setlocal expandtab
if &filetype != 'd'
setlocal filetype=d
endif
setlocal foldcolumn=0
setlocal foldenable
setlocal foldexpr=0
setlocal foldignore=#
setlocal foldlevel=99
setlocal foldmarker={{{,}}}
set foldmethod=indent
setlocal foldmethod=indent
setlocal foldminlines=1
setlocal foldnestmax=20
setlocal foldtext=foldtext()
setlocal formatexpr=
setlocal formatoptions=tcq
setlocal formatlistpat=^\\s*\\d\\+[\\]:.)}\\t\ ]\\s*
setlocal grepprg=
setlocal iminsert=2
setlocal imsearch=2
setlocal include=
setlocal includeexpr=
setlocal indentexpr=
setlocal indentkeys=0{,0},:,0#,!^F,o,O,e
setlocal noinfercase
setlocal iskeyword=@,48-57,_,192-255
setlocal keywordprg=
setlocal nolinebreak
setlocal nolisp
setlocal nolist
setlocal nomacmeta
setlocal makeprg=
setlocal matchpairs=(:),{:},[:]
setlocal modeline
setlocal modifiable
setlocal nrformats=octal,hex
set number
setlocal number
setlocal numberwidth=4
setlocal omnifunc=
setlocal path=
setlocal nopreserveindent
setlocal nopreviewwindow
setlocal quoteescape=\\
setlocal noreadonly
setlocal norelativenumber
setlocal norightleft
setlocal rightleftcmd=search
setlocal noscrollbind
setlocal shiftwidth=4
setlocal noshortname
setlocal nosmartindent
setlocal softtabstop=3
setlocal nospell
setlocal spellcapcheck=
setlocal spellfile=
setlocal spelllang=en
setlocal statusline=
setlocal suffixesadd=
setlocal noswapfile
setlocal synmaxcol=3000
if &syntax != 'd'
setlocal syntax=d
endif
setlocal tabstop=3
setlocal tags=
setlocal textwidth=108
setlocal thesaurus=
setlocal noundofile
setlocal nowinfixheight
setlocal nowinfixwidth
setlocal wrap
setlocal wrapmargin=0
5
normal zo
291
normal zo
293
normal zo
294
normal zo
293
normal zo
291
normal zo
430
normal zo
542
normal zo
563
normal zo
563
normal zo
589
normal zo
589
normal zo
599
normal zo
604
normal zo
610
normal zo
611
normal zo
617
normal zo
619
normal zo
619
normal zo
629
normal zo
619
normal zo
619
normal zo
635
normal zo
636
normal zo
639
normal zo
642
normal zo
642
normal zo
642
normal zo
642
normal zo
642
normal zo
645
normal zo
645
normal zo
645
normal zo
645
normal zo
645
normal zo
647
normal zo
647
normal zo
647
normal zo
647
normal zo
647
normal zo
639
normal zo
635
normal zo
652
normal zo
656
normal zo
703
normal zo
710
normal zo
712
normal zo
713
normal zo
712
normal zo
710
normal zo
703
normal zo
756
normal zo
610
normal zo
604
normal zo
749
normal zo
749
normal zo
542
normal zo
let s:l = 621 - ((7 * winheight(0) + 15) / 30)
if s:l < 1 | let s:l = 1 | endif
exe s:l
normal! zt
621
normal! 031l
tabedit ~/zd/Session.vim
set splitbelow splitright
wincmd _ | wincmd |
split
1wincmd k
wincmd w
set nosplitbelow
set nosplitright
wincmd t
set winheight=1 winwidth=1
exe '1resize ' . ((&lines * 25 + 16) / 32)
exe '2resize ' . ((&lines * 4 + 16) / 32)
argglobal
edit /Applications/MacVim.app/Contents/Resources/vim/runtime/doc/starting.txt
setlocal keymap=
setlocal noarabic
setlocal autoindent
setlocal balloonexpr=
setlocal nobinary
setlocal bufhidden=
setlocal nobuflisted
setlocal buftype=help
setlocal nocindent
setlocal cinkeys=0{,0},0),:,0#,!^F,o,O,e
setlocal cinoptions=
setlocal cinwords=if,else,while,do,for,switch
setlocal colorcolumn=
setlocal comments=s1:/*,mb:*,ex:*/,://,b:#,:%,:XCOMM,n:>,fb:-
setlocal commentstring=/*%s*/
setlocal complete=.,w,b,u,t,i
setlocal concealcursor=
setlocal conceallevel=0
setlocal completefunc=
setlocal nocopyindent
setlocal cryptmethod=
setlocal nocursorbind
setlocal nocursorcolumn
set cursorline
setlocal cursorline
setlocal define=
setlocal dictionary=
setlocal nodiff
setlocal equalprg=
setlocal errorformat=
setlocal expandtab
if &filetype != 'help'
setlocal filetype=help
endif
setlocal foldcolumn=0
setlocal nofoldenable
setlocal foldexpr=0
setlocal foldignore=#
setlocal foldlevel=99
setlocal foldmarker={{{,}}}
set foldmethod=indent
setlocal foldmethod=indent
setlocal foldminlines=1
setlocal foldnestmax=20
setlocal foldtext=foldtext()
setlocal formatexpr=
setlocal formatoptions=tcq
setlocal formatlistpat=^\\s*\\d\\+[\\]:.)}\\t\ ]\\s*
setlocal grepprg=
setlocal iminsert=2
setlocal imsearch=2
setlocal include=
setlocal includeexpr=
setlocal indentexpr=
setlocal indentkeys=0{,0},:,0#,!^F,o,O,e
setlocal noinfercase
setlocal iskeyword=!-~,^*,^|,^\",192-255
setlocal keywordprg=
setlocal nolinebreak
setlocal nolisp
setlocal nolist
setlocal nomacmeta
setlocal makeprg=
setlocal matchpairs=(:),{:},[:]
setlocal modeline
setlocal nomodifiable
setlocal nrformats=octal,hex
set number
setlocal nonumber
setlocal numberwidth=4
setlocal omnifunc=
setlocal path=
setlocal nopreserveindent
setlocal nopreviewwindow
setlocal quoteescape=\\
setlocal readonly
setlocal norelativenumber
setlocal norightleft
setlocal rightleftcmd=search
setlocal noscrollbind
setlocal shiftwidth=4
setlocal noshortname
setlocal nosmartindent
setlocal softtabstop=3
setlocal nospell
setlocal spellcapcheck=
setlocal spellfile=
setlocal spelllang=en
setlocal statusline=
setlocal suffixesadd=
setlocal noswapfile
setlocal synmaxcol=3000
if &syntax != 'help'
setlocal syntax=help
endif
setlocal tabstop=8
setlocal tags=
setlocal textwidth=78
setlocal thesaurus=
setlocal noundofile
setlocal nowinfixheight
setlocal nowinfixwidth
setlocal wrap
setlocal wrapmargin=0
let s:l = 1201 - ((0 * winheight(0) + 12) / 25)
if s:l < 1 | let s:l = 1 | endif
exe s:l
normal! zt
1201
normal! 07l
lcd ~/zd/zddmd/dmd
wincmd w
argglobal
setlocal keymap=
setlocal noarabic
setlocal autoindent
setlocal balloonexpr=
setlocal nobinary
setlocal bufhidden=
setlocal buflisted
setlocal buftype=
setlocal nocindent
setlocal cinkeys=0{,0},0),:,0#,!^F,o,O,e
setlocal cinoptions=
setlocal cinwords=if,else,while,do,for,switch
setlocal colorcolumn=
setlocal comments=s1:/*,mb:*,ex:*/,://,b:#,:%,:XCOMM,n:>,fb:-
setlocal commentstring=/*%s*/
setlocal complete=.,w,b,u,t,i
setlocal concealcursor=
setlocal conceallevel=0
setlocal completefunc=
setlocal nocopyindent
setlocal cryptmethod=
setlocal nocursorbind
setlocal nocursorcolumn
set cursorline
setlocal cursorline
setlocal define=
setlocal dictionary=
setlocal nodiff
setlocal equalprg=
setlocal errorformat=
setlocal expandtab
if &filetype != 'vim'
setlocal filetype=vim
endif
setlocal foldcolumn=0
setlocal foldenable
setlocal foldexpr=0
setlocal foldignore=#
setlocal foldlevel=99
setlocal foldmarker={{{,}}}
set foldmethod=indent
setlocal foldmethod=indent
setlocal foldminlines=1
setlocal foldnestmax=20
setlocal foldtext=foldtext()
setlocal formatexpr=
setlocal formatoptions=tcq
setlocal formatlistpat=^\\s*\\d\\+[\\]:.)}\\t\ ]\\s*
setlocal grepprg=
setlocal iminsert=2
setlocal imsearch=2
setlocal include=
setlocal includeexpr=
setlocal indentexpr=
setlocal indentkeys=0{,0},:,0#,!^F,o,O,e
setlocal noinfercase
setlocal iskeyword=@,48-57,_,192-255
setlocal keywordprg=
setlocal nolinebreak
setlocal nolisp
setlocal nolist
setlocal nomacmeta
setlocal makeprg=
setlocal matchpairs=(:),{:},[:]
setlocal modeline
setlocal modifiable
setlocal nrformats=octal,hex
set number
setlocal number
setlocal numberwidth=4
setlocal omnifunc=
setlocal path=
setlocal nopreserveindent
setlocal nopreviewwindow
setlocal quoteescape=\\
setlocal noreadonly
setlocal norelativenumber
setlocal norightleft
setlocal rightleftcmd=search
setlocal noscrollbind
setlocal shiftwidth=4
setlocal noshortname
setlocal nosmartindent
setlocal softtabstop=3
setlocal nospell
setlocal spellcapcheck=
setlocal spellfile=
setlocal spelllang=en
setlocal statusline=
setlocal suffixesadd=
setlocal noswapfile
setlocal synmaxcol=3000
if &syntax != 'vim'
setlocal syntax=vim
endif
setlocal tabstop=3
setlocal tags=
setlocal textwidth=80
setlocal thesaurus=
setlocal noundofile
setlocal nowinfixheight
setlocal nowinfixwidth
setlocal wrap
setlocal wrapmargin=0
let s:l = 25 - ((3 * winheight(0) + 2) / 4)
if s:l < 1 | let s:l = 1 | endif
exe s:l
normal! zt
25
normal! 0
lcd ~/zd/zddmd/dmd
wincmd w
exe '1resize ' . ((&lines * 25 + 16) / 32)
exe '2resize ' . ((&lines * 4 + 16) / 32)
tabnext 5
if exists('s:wipebuf')
  silent exe 'bwipe ' . s:wipebuf
endif
unlet! s:wipebuf
set winheight=25 winwidth=72 shortmess=filnxtToO
let s:sx = expand("<sfile>:p:r")."x.vim"
if file_readable(s:sx)
  exe "source " . fnameescape(s:sx)
endif
let &so = s:so_save | let &siso = s:siso_save
doautoall SessionLoadPost
unlet SessionLoad
" vim: set ft=vim :
