package Todo::Web;

use strict;
use warnings;
use utf8;
use Kossy;
use Config::Simple;
use DateTime::Format::Strptime;
use Todo::Model;
use FindBin;
use lib "$FindBin::Bin/../../lib";
use DateTime;
use Config::Simple;

filter 'set_title' => sub {
    my $app = shift;
    sub {
        my ( $self, $c )  = @_;
        $c->stash->{site_name} = __PACKAGE__;
        $app->($self,$c);
    }
};

get '/' => [qw/set_title/] => sub {
    my ( $self, $c )  = @_;
    my @todos = $self->db->search( 'todos', {}, {order_by => 'due_at ASC'});
    $c->render('index.tx', { todos => \@todos } );
};

post '/add' => sub{
    my ($self, $c) = @_;
    my $result = $c->req->validator([
        'text' => {
            default => 'hogehoge',
            rule => [
                ['NOT_NULL', 'empty text'],
            ],
        },
        'due_at' => {
            default => '1111-11-11 11:11:11', # ←なくてもok
            rule => [
                ['NOT_NULL', 'empty due'],
            ],
        }
    ]);
    my $row = $self->create_todo(map {$result->valid($_)} qw/text due_at/ );
    $c->render_json({response => $row});
};

post '/delete' => sub {
    my ($self, $c) = @_;
    my $id = $c->req->param('id');
    my $deleted_counts = $self->delete_todo( $id );

    if( $deleted_counts != 1 ){
	return $c->render_json({response => 'false'});
    }
    $c->render_json({response => 'true'});
};

# update method
post '/update' => sub {
    my ($self, $c) = @_;
    my $result = $c->req->validator([
        'text' => {
            default => 'hogehoge',
            rule => [
                ['NOT_NULL', 'empty text'],
            ],
        },
        'due_at' => {
            default => '1111-11-11 11:11:11', # ←なくてもok
            rule => [
                ['NOT_NULL', 'empty due'],
            ],
        }
    ]);
    my $todo = $self->update_todo($c->req->param('id'),$result->valid('text'), $result->valid('due_at'),$c->req->param('done'));
    $c->render_json({response => 'true'});
};


sub db {
	my $self = shift;
	if (!defined($self->{_db})) {
		my $config = new Config::Simple('config.pm');
		my $cfg = $config->vars();
		$self->{_db} = Todo::Model->new(connect_info => [
			$cfg->{'mysql.dsn'},
			$cfg->{'mysql.user'},
			$cfg->{'mysql.pass'},
			{ mysql_enable_utf8 => 1 },
		]);
	}
	$self->{_db};
}

sub create_todo {
    my ($self, $text, $due) = @_;
    $text = "" if !defined $text;
    my $row = $self->db->insert( 'todos', {
	text => $text,
	due_at => $self->create_datetime($due),
	done => 0,
	created_at => $self->now_datetime,
	updated_at => $self->now_datetime,
    });
    \%{$row->get_columns};
}


sub update_todo {
    my ($self, $id, $text, $due_at, $done) = @_;
    my $db = $self->db;
    my $update_row_count = $db->update('todos',
				   {
				       text => $text,
				       due_at => $self->create_datetime($due_at),
				       done => $done,
				   },
				   {
				       id => $id,
				   },
				   );
    my $row = $db->single('todos', {
        id => $id,
    });
    return \%{$row->get_columns};
}

sub delete_todo {
    my ($self, $id) = @_;
    if( !defined($id) ){
	return -1;
    }
    $self->db->delete('todos', {id => $id});
};

sub now_datetime {
    my $self = shift;
    DateTime->now(time_zone => 'Asia/Tokyo');
}

sub create_datetime {
    my ($self, $string_time) = @_;
    if(!$string_time){
	$string_time = '2000-10-22 22:22:22';
    }

    my $strp = DateTime::Format::Strptime->new(
	pattern => '%Y-%m-%d %H:%M:%S' # 文字列のパターンを指定
    );
    $strp->parse_datetime($string_time);
}

1;

