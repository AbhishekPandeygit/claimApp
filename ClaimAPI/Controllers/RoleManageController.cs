using ClaimAPI.Models;
using ClaimAPI.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;

namespace ClaimAPI.Controllers
{
    [Authorize]
    [Route("api/[controller]")]
    [ApiController]
    public class RoleManageController : ControllerBase
    {
        public IRole RoleService { get; }
        private APIResponse response = new APIResponse();

        public RoleManageController(IRole _roleService)
        {
            RoleService = _roleService;
        }

        [HttpGet]
        [Route("GetAllRoles")]
        public IActionResult GetAllRoles()
        {
            try
            {

                var result = RoleService.GetData();
                if (string.IsNullOrEmpty(result.Item1))
                {
                    response.status = 200;
                    response.ok = true;
                    response.data = result.Item2;
                    response.message = "Record found!";
                }
                else
                {
                    response.status = -100;
                    response.ok = false;
                    response.data = null;
                    response.message = result.Item1;

                }
            }
            catch (Exception ex)
            {
                response.status = -100;
                response.ok = false;
                response.data = null;
                response.message = ex.Message;
            }
            return Ok(response);
        }


        [HttpGet]
        [Route("GetRoleById")]
        public IActionResult GetRoleById(int id)
        {
            try
            {

                var result = RoleService.GetSingleRole(id);
                if (string.IsNullOrEmpty(result.Item1))
                {
                    response.status = 200;
                    response.ok = true;
                    response.data = result.Item2;
                    response.message = "Record found!";
                }
                else
                {
                    response.status = -100;
                    response.ok = false;
                    response.data = null;
                    response.message = result.Item1;

                }
            }
            catch (Exception ex)
            {
                response.status = -100;
                response.ok = false;
                response.data = null;
                response.message = ex.Message;
            }
            return Ok(response);
        }


        [HttpPost]
        [Route("CreateRole")]
        public IActionResult CreateRole()
        {
            try
            {
                Role role = new Role();
                role.RoleName = Request.Form["RoleName"].ToString();
                role.Status = Convert.ToInt32(Request.Form["Status"]);

                var result = RoleService.AddRole(role);
                if (string.IsNullOrEmpty(result))
                {
                    response.status = 200;
                    response.ok = true;
                    response.data = role;
                    response.message = "Data saved successfully!";
                }
                else
                {
                    response.status = -100;
                    response.ok = false;
                    response.data = null;
                    response.message = result;

                }
            }
            catch (Exception ex)
            {
                response.status = -100;
                response.ok = false;
                response.data = null;
                response.message = ex.Message;
            }
            return Ok(response);
        }


        [HttpPost]
        [Route("UpdateRole")]
        public IActionResult UpdateRole()
        {
            try
            {
                Role role = new Role();
                role.Id = Request.Form["Id"].ToString();
                role.RoleName = Request.Form["RoleName"].ToString();
                role.Status = Convert.ToInt32(Request.Form["Status"]);

                var result = RoleService.UpdateRole(role);
                if (string.IsNullOrEmpty(result))
                {
                    response.status = 200;
                    response.ok = true;
                    response.data = role;
                    response.message = "Data saved successfully!";
                }
                else
                {
                    response.status = -100;
                    response.ok = false;
                    response.data = null;
                    response.message = result;

                }
            }
            catch (Exception ex)
            {
                response.status = -100;
                response.ok = false;
                response.data = null;
                response.message = ex.Message;
            }
            return Ok(response);
        }

        [HttpPost]
        [Route("AssignRole")]
        public IActionResult AssignRole()
        {
            try
            {
               
                int RoleId = Convert.ToInt32(Request.Form["RoleId"]);
                int UserId = Convert.ToInt32(Request.Form["UserId"]);
                int Status = Convert.ToInt32(Request.Form["Status"]);

                var result = RoleService.AssignRole(RoleId,UserId,Status);
                if (string.IsNullOrEmpty(result))
                {
                    response.status = 200;
                    response.ok = true;
                    response.message = "Data saved successfully!";
                }
                else
                {
                    response.status = -100;
                    response.ok = false;
                    response.data = null;
                    response.message = result;

                }
            }
            catch (Exception ex)
            {
                response.status = -100;
                response.ok = false;
                response.data = null;
                response.message = ex.Message;
            }
            return Ok(response);
        }

        [HttpGet]
        [Route("GetRoles")]
        public IActionResult GetRoles()
        {
            try
            {

                var result = RoleService.GetRoles();
                if (string.IsNullOrEmpty(result.Item1))
                {
                    response.status = 200;
                    response.ok = true;
                    response.data = result.Item2;
                    response.message = "Record found!";
                }
                else
                {
                    response.status = -100;
                    response.ok = false;
                    response.data = null;
                    response.message = result.Item1;

                }
            }
            catch (Exception ex)
            {
                response.status = -100;
                response.ok = false;
                response.data = null;
                response.message = ex.Message;
            }
            return Ok(response);
        }
    }
}
