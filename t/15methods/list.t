use xcl::test;

let lst := (1, 2, 3);

is lst.pipe(x => { x + 1 }) (2, 3, 4) 'basic pipe';

is lst.pipe(x => { (x, x + 1) }) (1, 2, 2, 3, 3, 4) 'list pipe';

is lst.map(x => { x + 1 }) (2, 3, 4) 'basic map';

is lst.map(x => { (x, x + 1) }) ((1, 2), (2, 3), (3, 4)) 'list map';

let lst := (1, 0, 1, 0, 1);

is lst.where(x => { x }) (1, 1, 1) 'basic where';
