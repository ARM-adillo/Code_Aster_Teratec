#!/usr/bin/env python3

"""
This script creates environment files for a platform.
"""

import argparse
import importlib
import os
import os.path as osp
import re
import sys
import sysconfig

PYTHON_VERSION = "{0.major}.{0.minor}".format(sys.version_info)

USAGE = """
    generate_env [options]

  This script creates environment files for a platform.
"""

PREFIX = osp.abspath(osp.dirname(__file__))


def get_versions(filename="VERSION"):
    """Return a dict containing the version of each product.

    Arguments:
        filename (str): Input file.

    Returns:
        dict: Dict containing versions.
    """
    vers = {}
    with open(filename, "r") as fvers:
        exec(compile(fvers.read(), filename, "exec"), vers)
    del vers["__builtins__"]
    return vers


def check_modversion(mod, version):
    """Check if availability of a version of a module.

    Arguments:
        mod (str): module name.
        version (str): version to be checked.

    Returns:
        bool: *True* if the imported module has the same version.
    """
    try:
        mod = importlib.import_module(mod)
        return mod.__version__ == version
    except (ImportError, AttributeError):
        return False


class Products:
    """Collection of informations of installed products

    Arguments:
        variant (str): Variant of the configuration
        versions (dict): Dict containing products versions

    Attributes:
        _prod (list[dict]): 'products' collection for templating
    """

    def __init__(self, variant, root, versions):
        self._prod = {}
        self._variant = variant
        self._root = root
        self._vers = versions

    @property
    def products(self):
        """list[dict]: Attribute that holds the 'products' property."""
        return self._prod.values()

    def add(self, name, with_, path=None, version=None, includes=["include"], varname=None):
        """Store product informations"""
        name = name.upper()
        if not varname:
            varname = name
        if name not in self._vers:
            print("skipping {0}".format(name))
            return
        version = version or self._vers[name]
        if version == "None":
            return
        path = path or (name.lower() + "-" + version)
        home = "${PREREQ_PATH}/" + path
        values = self._prod.setdefault(varname, {"name": varname})
        values["home"] = home
        values["version"] = version
        if "path" in with_:
            values["path"] = home + "/bin"
        if "libpath" in with_:
            values["libpath"] = home + "/lib"
        if "includes" in with_:
            values["includes"] = " ".join([home + "/" + i for i in includes])
        if "pypath" in with_:
            values["pypath"] = home + "/lib/python{0}/site-packages".format(self._vers["PYTHON"])

    def manual(self, name, **kwds):
        """Add manually values for a product"""
        values = self._prod.setdefault(name.upper(), {"name": name.upper()})
        values.update(kwds)

    def get(self, name, key):
        """Return the value of a variable of a product."""
        values = self._prod.get(name.upper(), {})
        return values.get(key)

    def patch_lib64py(self, name):
        """Patch for lib64/pythonX.Y"""
        values = self._prod.setdefault(name.upper(), {"name": name.upper()})
        if values.get("pypath"):
            values["pypath"] = values["pypath"].replace("lib/python", "lib64/python")

    def check(self):
        """Check paths."""
        env = os.environ.copy()
        os.environ["PREREQ_PATH"] = self._root
        # paths are separated by a space (includes) or a colon (others)
        re_sep = re.compile("[ :]")
        errors = []
        for values in self._prod.values():
            for info in values.values():
                for path in re_sep.split(info):
                    if "/" not in path:
                        continue
                    if not osp.exists(osp.expandvars(path)):
                        errors.append(path)
        os.environ = env
        if errors:
            # remove --check option to see the generated environment file
            raise FileNotFoundError(" ".join(errors))


def generate_env_main(args):
    """Generate environment files.

    Arguments:
        args (dict): Dict providing the *required* keys (except those that
            are deduced from others).
    """
    versions = get_versions(args["version_file"])
    versions["PYTHON"] = args["python"]

    # variables required by template
    variant = args["variant"]
    kwds = {
        "distr": args["os"],
        "variant": variant,
        "root": args["root"],
        "version": versions["VERSION"],
        "parallel": 1 if variant == "mpi" else 0,
        "addon": args["addon"],
    }

    coll = Products(variant, args["root"], versions)
    # add Python first: use prereq paths, then python (or eventually venv), then system.
    # NB: code_aster itself inserts selected Python bin path first.
    paths = sysconfig.get_paths("posix_prefix")
    coll.manual(
        "PYTHON", path=sys.prefix + "/bin", pypath=paths["purelib"] + ":" + paths["platlib"]
    )

    coll.add("HDF5", ("libpath", "includes"))
    coll.add("MED", ("path", "libpath", "includes", "pypath"))
    coll.add("METIS", ("libpath", "includes"))
    mfront_inc = ["include/TFEL-" + versions["MFRONT"]]
    coll.add("MFRONT", ("path", "libpath", "includes"), includes=mfront_inc)
    coll.add("MGIS", ("libpath", "includes"))
    coll.add("HOMARD", ("path",))
    coll.add("SCOTCH", ("libpath", "includes"))
    mumps_inc = ["include", "include_seq"] if variant == "seq" else ["include"]
    coll.add("MUMPS", ("libpath", "includes"), includes=mumps_inc)
    coll.add("MISS3D", ("path",))
    coll.add("MEDCOUPLING", ("libpath", "includes", "pypath"))
    coll.add("ECREVISSE", ("path",))
    coll.add("GMSH", ("path",))
    coll.add("GRACE", ("path",))
    coll.add("ASRUN", ("path", "pypath"))
    # python modules that may be provided by the system
    sys_mpi4py = check_modversion("mpi4py", versions["MPI4PY"])

    if variant == "mpi":
        if not sys_mpi4py:
            coll.add("MPI4PY", ("pypath",))
        coll.add("PARMETIS", ("libpath", "includes"))
        coll.add(
            "SCALAPACK",
            ("libpath",),
            varname="MATH",
            version=versions.get("SCALAPACK", "0"),
            path="scalapack-" + versions.get("SCALAPACK", "0"),
        )
        # addons for petsc4py
        coll.add("PETSC", ("libpath", "includes"), includes=["include", "lib/petsc4py/include"])
        coll.manual("PETSC", pypath=coll.get("PETSC", "libpath"))

    # /!\ patches
    # lib vs lib64
    if kwds["distr"] in ("cronos", "centos8"):
        assert not sys_mpi4py, "should not be also provided by the system"
        coll.patch_lib64py("MED")
        coll.patch_lib64py("MPI4PY")
    # boost
    if kwds["distr"] == "centos8":
        coll.manual("BOOST", libpath="/usr/lib64", includes="/usr/include")
    elif kwds["distr"] == "ubuntu18":
        coll.manual("BOOST", libpath="/usr/lib/x86_64-linux-gnu", includes="/usr/include")
    else:
        coll.manual(
            "BOOST",
            boost_python=os.environ.get("BOOST_LIB", "boost_python3"),
            libpath=os.environ.get("BOOST_ROOT", "/usr") + "/lib",
            includes=os.environ.get("BOOST_ROOT", "/usr") + "/include",
        )

    if args["check"]:
        coll.check()
    text = EnvTemplate.render(products=coll.products, **kwds)

    suffix = "std" if variant == "seq" else variant
    env_file = osp.join(args["destdir"] or ".", kwds["distr"] + "_" + suffix + ".sh")
    with open(env_file, "w") as fenv:
        fenv.write(text)
    print("created:", env_file)


class EnvTemplate:
    """Template for environment file (to avoid Jinja2 dependency)."""

    part0 = """# This file set the environment for code_aster.
# Configuration for {distr} {variant}
if [ ! -z "${{ASTER_PROFILE_LOADED}}" ]; then
    return
fi
export WAFBUILD_ENV=$(readlink -n -f ${{BASH_SOURCE}})

# DEVTOOLS_COMPUTER_ID avoids waf to re-source the environment
export DEVTOOLS_COMPUTER_ID={distr}

export PREREQ_PATH={root}
export PREREQ_VERSION={version}
"""
    part1 = """
# force parallel build
export ENABLE_MPI={parallel}
"""
    part2 = """
export LINKFLAGS="${{LINKFLAGS}} -Wl,--no-as-needed"

# prerequisites paths"""
    part_mfront = '''
export TFELHOME="{home}"
export TFELVERS="{version}"'''
    part_boost = '''
export LIB_BOOST="{boost_python}"'''
    part_libpath = '''
export LIBPATH_{name}="{libpath}"'''
    part_home = '''
export PATH_{name}="{home}"'''
    part_includes = '''
export INCLUDES_{name}="{includes}"'''
    part_pypath = '''
export PYPATH_{name}="{pypath}"'''
    part_path = '''
export PATH="{path}:${{PATH}}"'''
    part_ld_library_path = '''
export LD_LIBRARY_PATH="${{LIBPATH_{name}}}:${{LD_LIBRARY_PATH}}"'''
    part_ld_library_path_append = '''
export LD_LIBRARY_PATH="${{LD_LIBRARY_PATH}}:${{LIBPATH_{name}}}"'''
    part_pythonpath = '''
export PYTHONPATH="${{PYPATH_{name}}}:${{PYTHONPATH}}"'''
    part9 = '''
export LINKFLAGS="${{LINKFLAGS}} -Wl,-rpath=${{LD_LIBRARY_PATH}}"'''

    @classmethod
    def render(cls, **kwargs):
        """Rendering"""
        text = cls.part0.format(**kwargs)
        text += cls.part1.format(**kwargs)
        if kwargs["addon"]:
            with open(kwargs["addon"]) as addon:
                text += addon.read()
        text += cls.part2.format(**kwargs)
        for prod in kwargs["products"]:
            if prod["name"] == "MFRONT":
                text += cls.part_mfront.format(**prod)
            if prod["name"] == "BOOST":
                prod.setdefault("boost_python", "boost_python3")
                text += cls.part_boost.format(**prod)
            if prod.get("home"):
                text += cls.part_home.format(**prod)
            if prod.get("libpath"):
                text += cls.part_libpath.format(**prod)
            if prod.get("includes"):
                text += cls.part_includes.format(**prod)
            if prod.get("pypath"):
                text += cls.part_pypath.format(**prod)
            if prod.get("path"):
                text += cls.part_path.format(**prod)
            if prod.get("libpath"):
                if prod["libpath"].startswith("/usr/"):
                    text += cls.part_ld_library_path_append.format(**prod)
                else:
                    text += cls.part_ld_library_path.format(**prod)
            if prod.get("pypath"):
                text += cls.part_pythonpath.format(**prod)
            text += "\n"
        text += cls.part9.format(**kwargs)
        return text


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        usage=USAGE, formatter_class=argparse.ArgumentDefaultsHelpFormatter
    )
    parser.add_argument("-s", "--os", action="store", help="name of the distribution")
    parser.add_argument("--variant", action="store", help="variant: 'seq' or 'mpi'")
    parser.add_argument("--root", action="store", help="prerequisites root directory")
    parser.add_argument(
        "--version_file",
        action="store",
        default="VERSION",
        help="filename containing products versions",
    )
    parser.add_argument("--addon", action="store", help="")
    parser.add_argument("--check", action="store_true", help="check existence of directories")
    parser.add_argument(
        "--python", action="store", default=PYTHON_VERSION, help="version of Python"
    )
    parser.add_argument(
        "--dest",
        action="store",
        dest="destdir",
        default=".",
        help="destination directory " "(default: current directory)",
    )
    args = parser.parse_args()
    if not args.os:
        parser.error("'-s/--os' option is required")
    if not args.root:
        parser.error("'--root' option is required")
    if args.variant not in ("seq", "mpi"):
        parser.error("'--variant' must be 'seq' or 'mpi'")

    generate_env_main(vars(args))
