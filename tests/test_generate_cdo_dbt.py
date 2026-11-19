"""CDO generation preserves explicitly defined, team-owned extension metrics."""
import importlib.util
from pathlib import Path
import yaml

SCRIPT = Path(__file__).resolve().parents[1] / "scripts" / "generate_cdo_dbt.py"
spec = importlib.util.spec_from_file_location("generate_cdo_dbt", SCRIPT)
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)


def test_cdo_retains_team_approved_metrics_and_null_branches(tmp_path):
    common = ["position_id", "report_date", "profit_loss", "instrument_code"]
    columns = [{"name": x, "data_type": {"position_id": "text", "report_date": "date", "profit_loss": "numeric", "instrument_code": "integer"}[x]} for x in common]
    catalog = {
        "catalog_format": "cdo-federated-semantic-catalog/v1",
        "contract": {"name": "cdo.position", "version": 1},
        "common_attributes": common,
        "implementations": [
            {"semantic_model": "team_a_equity_positions", "source_model": "stg_team_a_positions", "owner": "lob_team_a",
             "columns": columns + [{"name": "mtm", "data_type": "numeric"}, {"name": "cash", "data_type": "numeric"}],
             "metrics": [
                 {"name": "equity_total_mtm", "type": "simple", "agg": "sum", "expr": "mtm"},
                 {"name": "equity_total_cash", "type": "simple", "agg": "sum", "expr": "cash"}]},
            {"semantic_model": "team_c_fi_positions", "source_model": "stg_team_c_positions", "owner": "lob_team_c",
             "columns": columns + [{"name": "settled_cash", "data_type": "numeric"}],
             "metrics": [{"name": "fi_total_settled_cash", "type": "simple", "agg": "sum", "expr": "settled_cash"}]},
        ],
    }
    src = tmp_path / "source.yml"
    src.write_text(yaml.safe_dump(catalog))
    path = module.generate(src, tmp_path / "generated")
    model = yaml.safe_load(path.read_text())["models"][0]
    metrics = {m["name"]: m for m in model["metrics"]}
    assert {"cdo_equity_total_mtm", "cdo_equity_total_cash", "cdo_fi_total_settled_cash"} <= set(metrics)
    assert metrics["cdo_equity_total_mtm"]["expr"] == "mtm"
    assert metrics["cdo_fi_total_settled_cash"]["config"]["meta"]["source_team_metric"] == "fi_total_settled_cash"
    sql = (tmp_path / "generated" / "cdo_enterprise_positions.sql").read_text()
    assert "null::numeric as settled_cash" in sql
    assert "null::numeric as mtm" in sql
